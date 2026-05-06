# Résumé de `registration_service.dart`

**But :** Service de gestion des inscriptions, refus, confirmations de présence
et choix de collation aux rencontres. Toutes les mutations ciblent la table
`registrations`. Utilisé par `EventCard`, `AdminEventsPage` et `EventService`.

---

## Constante de sélection

```dart
static const _eventSelect = '*, registrations(user_id, status, has_collation)';
```

Identique à `EventService._select` — permet à `Event.fromMap` de reconstruire
les listes de participants depuis le join `registrations`.

---

## Statuts des registrations

| Statut | Signification |
|---|---|
| `'registered'` | Inscrit, présence non encore confirmée |
| `'confirmed'` | Présence confirmée (événement en cours) |
| `'declined'` | A explicitement refusé l'événement |

---

## Inscriptions

| Méthode | Opération | Détail |
|---|---|---|
| `registerUserToEvent` | INSERT | `status: 'registered'` |
| `unregisterUserFromEvent` | DELETE | Filtre `(event_id, user_id)` |
| `declineEvent` | UPSERT | `status: 'declined'` + `responded_at: now()` |
| `cancelDecline` | DELETE | Filtre `(event_id, user_id, status == 'declined')` |

> `declineEvent` utilise un **UPSERT** (pas un INSERT) pour gérer le cas où
> une inscription existe déjà — évite une erreur de contrainte unique.
> `cancelDecline` supprime uniquement si le statut est `'declined'` — protège
> contre la suppression d'une inscription active par erreur.

---

## Collation

| Méthode | Opération | Champ |
|---|---|---|
| `saveCollationChoice(eventId, userId, participates)` | UPDATE | `has_collation: participates` |
| `removeCollationChoice(eventId, userId)` | UPDATE | `has_collation: false` |

Les deux méthodes filtrent sur `(event_id, user_id)` — la ligne doit exister.

---

## Récupération des événements de l'utilisateur

Toutes les méthodes suivent le même pattern en deux requêtes :
1. SELECT `event_id` depuis `registrations` (avec filtre sur `user_id` + statut)
2. SELECT événements complets depuis `events` avec `.inFilter('id', eventIds)`

| Méthode | Filtre statut | Type |
|---|---|---|
| `getUserRegisteredEvents` | `!= 'declined'` | `Future<List<Event>>` |
| `getUserRegisteredEventsStream` | `!= 'declined'` | `Stream<List<Event>>` |
| `getUserConfirmedEvents` | `== 'confirmed'` | `Future<List<Event>>` |
| `getUserConfirmedEventsStream` | `== 'confirmed'` | `Stream<List<Event>>` |

Les streams utilisent `.asyncMap` sur le stream `registrations` pour charger
les événements à chaque changement — même pattern que `EventService.getUserEventsStream`.

---

## Confirmation de présence

| Méthode | UPDATE champs |
|---|---|
| `confirmUserPresence` | `status → 'confirmed'`, `responded_at → now()` |
| `removePresenceConfirmation` | `status → 'registered'`, `responded_at → null` |

Contrairement à `EventService.confirmUserPresence`, cette version ne vérifie
**pas** que l'événement est `started` ni que l'utilisateur est inscrit —
la validation est supposée effectuée côté widget.

---

## Vérifications et compteurs

| Méthode | Filtre | Retour |
|---|---|---|
| `isUserRegistered(eventId, userId)` | `.maybeSingle()` → `status in ['registered', 'confirmed']` | `bool` |
| `isUserConfirmed(eventId, userId)` | `.maybeSingle()` → `status == 'confirmed'` | `bool` |
| `getRegisteredCount(eventId)` | `status != 'declined'` | `int` |
| `getConfirmedCount(eventId)` | `status == 'confirmed'` | `int` |

---

## Récupération des utilisateurs avec join

### `getRegisteredUsers(eventId)` / `getConfirmedUsers(eventId)`

Effectuent un join direct dans Supabase :
```dart
.select('user_id, users(id, email, nom, prenom, role, phone)')
```

Construisent des objets `user_model.User` via `_userFromMap()`.
Seuls les champs de base sont chargés (pas `photo_url`, `company_name`, etc.).

### `_userFromMap(Map)` (helper privé)

Construit un `User` minimal depuis le join. Rôle par défaut si `null` :
`adherent` (contrairement à `AuthService._parseRole` qui retourne `invite`).

### `_parseUserRole(dynamic)` (helper privé)

Convertit le rôle en `UserRole`. Rôle inconnu → `adherent` (différent du
comportement de `AuthService` qui retourne `invite` par défaut).

---

## Table Supabase

| Table | Opérations | Champs concernés |
|---|---|---|
| `registrations` | SELECT, INSERT, UPDATE, DELETE, UPSERT, stream Realtime | `event_id`, `user_id`, `status`, `has_collation`, `responded_at` |
| `events` | SELECT (avec join) | `*` + `registrations(user_id, status, has_collation)` |
| `users` | SELECT (join via registrations) | `id`, `email`, `nom`, `prenom`, `role`, `phone` |

---

## Relation avec `EventService`

`RegistrationService` et `EventService` partagent plusieurs méthodes similaires
(`registerUserToEvent`, `confirmUserPresence`, etc.). `RegistrationService`
est le service dédié aux inscriptions côté **utilisateur**, tandis que
`EventService` centralise les opérations côté **admin** avec des validations
métier supplémentaires (vérification capacité, statut événement).
