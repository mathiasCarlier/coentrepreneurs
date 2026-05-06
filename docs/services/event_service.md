# Résumé de `event_service.dart`

**But :** Service central de gestion des événements et des inscriptions.
Fournit toutes les opérations CRUD, les streams Realtime, la gestion des
inscriptions/confirmations et les statistiques. Consommé par `AdminEventsPage`,
`AllEventsPage`, `home_page` et `EventCard`.

---

## Constante de sélection

```dart
static const _select = '*, registrations(user_id, status, has_collation)';
```

Utilisée dans toutes les requêtes SELECT — effectue un join automatique avec
la table `registrations` pour que `Event.fromMap` puisse reconstruire les
listes de participants en une seule requête.

---

## CRUD Événements

| Méthode | Opération Supabase | Détail |
|---|---|---|
| `createEvent(event)` | INSERT | Supprime `id` de la map avant insertion (UUID généré par Supabase) |
| `updateEvent(eventId, event)` | UPDATE | Supprime `id` de la map, filtre sur `id` |
| `deleteEvent(eventId)` | DELETE | Supprime en cascade les `registrations` (si FK configurée) |
| `updateEventSummary(eventId, summary)` | UPDATE | Met à jour uniquement `summary` |
| `updateEventStatus(eventId, newStatus)` | UPDATE | Persiste `newStatus.name` dans `status` |

---

## Lectures

### `getAllEventsStream()`

Stream personnalisé avec **double souscription Realtime** sur `events` ET
`registrations`. Toute modification dans l'une ou l'autre table déclenche
un rechargement complet via `getAllEvents()`.

Architecture interne :
```
StreamController<List<Event>>
├── eventsSub  → events.stream     → fetchAndEmit()
└── regsSub    → registrations.stream → fetchAndEmit()
```

`onCancel` annule les deux subscriptions et ferme le controller.

> Ce pattern est nécessaire car un stream Supabase sur `events` seul ne se
> déclenche pas lors d'une inscription (qui modifie `registrations`).

### `getAllEvents()`

SELECT avec `_select`, trié par `date` croissant. Retourne `List<Event>`.

### `getEvent(eventId)`

SELECT avec `_select` + `.maybeSingle()`. Retourne `Event?`.

### `getUserEventsStream(userId)`

Stream branché sur `registrations` filtré par `user_id`. À chaque émission,
charge les événements correspondants via `.inFilter('id', eventIds)`.
Exclut les registrations avec statut `'declined'`.

### `getUserEvents(userId)` / `getUserConfirmedEvents(userId)`

Versions `Future` des mêmes requêtes. `getUserConfirmedEvents` filtre sur
`status == 'confirmed'` uniquement.

### Autres lectures

| Méthode | Filtre Supabase |
|---|---|
| `getUpcomingEvents()` | `date > now()` + tri ASC |
| `getPastEvents()` | `date < now()` + tri DESC |
| `searchEventsByTheme(query)` | `.ilike('theme', '%query%')` |
| `countEvents()` | SELECT `id` → `.length` |
| `getConfirmedCount(eventId)` | `status == 'confirmed'` → `.length` |
| `getRegisteredUsers(eventId)` | Via `getEvent` → `registeredUserIds` |
| `getConfirmedUsers(eventId)` | Via `getEvent` → `confirmedParticipants` |

---

## Gestion des inscriptions

### `registerUserToEvent(eventId, userId)`

1. Charge l'événement via `getEvent`
2. Vérifie que l'événement existe et n'est pas complet (`event.isFull`)
3. INSERT dans `registrations` avec `status: 'registered'`

### `unregisterUserFromEvent(eventId, userId)`

DELETE dans `registrations` filtré sur `(event_id, user_id)`.

---

## Gestion des confirmations de présence

### `confirmUserPresence(eventId, userId)`

1. Charge l'événement
2. Vérifie que l'utilisateur est inscrit (`registeredUserIds.contains(uid)`)
3. Vérifie que l'événement est `started`
4. UPDATE `status → 'confirmed'` + `responded_at → now()`

### `removePresenceConfirmation(eventId, userId)`

UPDATE `status → 'registered'` + `responded_at → null`.

---

## Statistiques

### `getEventStats(eventId)`

Charge l'événement et retourne une `Map<String, dynamic>` avec :

| Clé | Valeur |
|---|---|
| `totalInscrits` | `currentParticipants` |
| `maxParticipants` | `maxParticipants` |
| `tauxRemplissage` | `registrationPercentage` (0.0–1.0) |
| `totalConfirmes` | `confirmedParticipants.length` |
| `tauxConfirmation` | `confirmedParticipants.length / currentParticipants` |
| `status` | `event.status.name` |

---

## Utilitaires

### `initializeDefaultEvents()`

Vérifie via `countEvents()` si des événements existent déjà.
Si la base est vide, insère 3 événements de démonstration (J+7, J+14, J+21).
Les erreurs sont loguées en debug sans être propagées — ne bloque pas le
démarrage de l'application.

### `clearAllEvents()`

DELETE sur tous les événements via `.neq('id', '')` (filtre universel).
Réservé aux opérations de maintenance.

---

## Tables Supabase

| Table | Opérations |
|---|---|
| `events` | SELECT (avec join), INSERT, UPDATE, DELETE, stream Realtime |
| `registrations` | SELECT, INSERT, UPDATE, DELETE, stream Realtime |

## Gestion des erreurs

Toutes les méthodes encapsulent les exceptions dans des `Exception` avec
messages français descriptifs. Les erreurs réseau sont propagées à l'appelant
— c'est l'UI qui décide de les afficher via SnackBar ou autre.