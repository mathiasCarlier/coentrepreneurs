# Résumé de `event.dart`

**But :** Modèle central représentant une rencontre de l'association. Gère le cycle
de vie complet d'un événement, la sérialisation Supabase et les calculs d'état dérivés.
Utilisé par `EventService`, `AdminEventsPage`, `AllEventsPage`, `EventCard` et
`home_page`.

---

## `EventStatus` (enum)

Trois états formant le cycle de vie d'une rencontre :

| Valeur | Signification |
|---|---|
| `pending` | Inscriptions ouvertes, rencontre à venir |
| `started` | Rencontre en cours, confirmations de présence ouvertes |
| `finished` | Rencontre terminée, collecte de feedback possible |

Transitions gérées par `_EventDetailsSheetState._toggleEventStatus()` dans
`admin_events_page.dart`. Les transitions sont **irréversibles** côté UI.

---

## Classe `Event`

### Champs obligatoires

| Champ | Type | Colonne Supabase |
|---|---|---|
| `id` | `String` | `id` |
| `date` | `DateTime` | `date` |
| `theme` | `String` | `theme` |
| `intervenant` | `String` | `intervenant` |
| `entreprise` | `String` | `entreprise` |
| `lieu` | `String` | `lieu` |
| `maxParticipants` | `int` | `max_participants` |

### Champs optionnels

| Champ | Type | Colonne Supabase |
|---|---|---|
| `summary` | `String?` | `summary` |
| `description` | `String?` | `description` |
| `linkUrl` | `String?` | `link_url` |
| `imageUrl` | `String?` | `image_url` |
| `fileUrl` | `String?` | `file_url` |
| `fileName` | `String?` | `file_name` |
| `collationMenuText` | `String?` | `collation_menu_text` |

### Listes de participants (reconstruites depuis `registrations`)

Ces listes ne sont **pas** stockées dans la table `events` — elles sont
reconstruites à la désérialisation depuis la clé `registrations` (join Supabase) :

| Champ | Statuts inclus |
|---|---|
| `registeredUserIds` | `'registered'` + `'confirmed'` |
| `confirmedParticipants` | `'confirmed'` uniquement |
| `declinedUserIds` | `'declined'` |
| `collationParticipants` | `has_collation == true` (indépendant du statut) |

---

## Getters calculés

### Capacité et remplissage

| Getter | Calcul | Retour |
|---|---|---|
| `currentParticipants` | `registeredUserIds.length` | `int` |
| `isFull` | `currentParticipants >= maxParticipants` | `bool` |
| `registrationPercentage` | `currentParticipants / maxParticipants` | `double` 0.0–1.0 |

### État

| Getter | Condition |
|---|---|
| `isStarted` | `status == EventStatus.started` |
| `isFinished` | `status == EventStatus.finished` |
| `hasCollation` | `collationMenuText` non null et non vide |
| `hasSummary` | `summary` non null et non vide |
| `hasTime` | `date.hour != 0 || date.minute != 0` |

### Affichage

| Getter | Exemple de sortie |
|---|---|
| `formattedDate` (sans heure) | `"15 mar 2025"` |
| `formattedDate` (avec heure) | `"15 mar 2025 à 18h30"` |

Mois en français via un tableau de 12 abréviations codé en dur (`'jan'`…`'déc'`).

### Validation des champs texte

`isDefinedIntervenant`, `isDefinedEntreprise`, `isDefinedLieu` — retournent
`true` si le champ correspondant est non vide. Utilisés par l'UI pour
afficher une valeur ou un état "à définir".

### Méthodes par utilisateur

| Méthode | Condition |
|---|---|
| `isUserRegistered(uid)` | `registeredUserIds.contains(uid)` |
| `isUserConfirmed(uid)` | `confirmedParticipants.contains(uid)` |
| `isUserDeclined(uid)` | `declinedUserIds.contains(uid)` |
| `canUserConfirm(uid)` | `isStarted && isUserRegistered(uid)` |
| `hasUserChosenCollation(uid)` | `collationParticipants.contains(uid)` |

---

## Sérialisation

### `toMap()`

Produit une `Map<String, dynamic>` en snake_case pour Supabase.
**N'inclut pas les listes de participants** (gérées via `registrations`).
Les champs optionnels sont inclus même si `null` (Supabase gère le `null` = effacement).

### `Event.fromMap(Map)`

Désérialise depuis une réponse Supabase pouvant contenir une clé `registrations`
(join). Itère sur chaque registration pour reconstruire les 4 listes de participants
en un seul passage (`O(n)`).

### `_statusFromString(String)` (statique, privée)

Convertit une chaîne Supabase en `EventStatus`. Tout statut non reconnu
retourne `EventStatus.pending` par défaut (sécurité).

---

## `copyWith`

Pattern standard de copie immuable avec **flags de suppression explicite** pour
les champs optionnels nullables :

| Flag | Effet |
|---|---|
| `clearSummary: true` | Force `summary = null` |
| `clearCollationMenuText: true` | Force `collationMenuText = null` |
| `clearDescription: true` | Force `description = null` |
| `clearLinkUrl: true` | Force `linkUrl = null` |
| `clearImageUrl: true` | Force `imageUrl = null` |
| `clearFileUrl: true` | Force `fileUrl = null` |
| `clearFileName: true` | Force `fileName = null` |

Ce mécanisme contourne la limitation du pattern `copyWith` classique qui ne
peut pas distinguer "ne pas modifier" de "mettre à null".

---

## Table Supabase associée

| Table | Relation |
|---|---|
| `events` | Données principales de l'événement |
| `registrations` | Join optionnel via `fromMap` — colonnes lues : `user_id`, `status`, `has_collation` |
```