# Résumé de `invitation.dart`

**But :** Modèle représentant une invitation envoyée par un adhérent à un tiers
pour participer à une rencontre. Utilisé par `EventGuestsSection` et le service
associé pour la gestion des invitations dans Supabase.

---

## `InvitationStatus` (enum)

| Valeur | Signification |
|---|---|
| `pending` | Invitation envoyée, en attente de réponse |
| `accepted` | Invité a accepté |
| `declined` | Invité a refusé |

Valeur par défaut à la création : `pending`.
Tout statut non reconnu dans `_statusFromString` retourne `pending` (sécurité).

---

## Classe `Invitation`

### Champs

| Champ | Type | Colonne Supabase | Rôle |
|---|---|---|---|
| `id` | `String` | `id` | UUID généré par Supabase |
| `eventId` | `String` | `event_id` | Référence vers la rencontre |
| `invitedByUserId` | `String` | `invited_by_user_id` | UID de l'adhérent invitant |
| `invitedUserEmail` | `String` | `invited_user_email` | Email de la personne invitée |
| `invitedUserPrenom` | `String` | `invited_user_prenom` | Prénom dénormalisé |
| `invitedUserNom` | `String` | `invited_user_nom` | Nom dénormalisé |
| `status` | `InvitationStatus` | `status` | Statut courant de l'invitation |
| `createdAt` | `DateTime` | `created_at` | Date d'envoi |
| `respondedAt` | `DateTime?` | `responded_at` | Date de réponse (null si pas encore répondu) |

> Les champs `invitedUserEmail`, `invitedUserPrenom` et `invitedUserNom` sont
> dénormalisés : la personne invitée peut ne pas avoir de compte dans l'application.

### Getters

| Getter | Condition |
|---|---|
| `invitedUserFullName` | `'$invitedUserPrenom $invitedUserNom'` |
| `isPending` | `status == InvitationStatus.pending` |
| `isAccepted` | `status == InvitationStatus.accepted` |
| `isDeclined` | `status == InvitationStatus.declined` |

---

## Méthodes

### `toMap()`

Sérialisation pour l'**insertion** Supabase uniquement.
N'inclut pas `id`, `created_at` ni `responded_at` — générés ou mis à jour
par la base. Le statut est sérialisé via `.name` (valeur textuelle de l'enum).

### `Invitation.fromMap(Map)`

Désérialisation depuis Supabase. Points notables :
- `createdAt` : fallback `DateTime.now()` si `null` (même limitation que `feedback.dart`)
- `respondedAt` : correctement nullable — `null` si absent, parsé sinon

### `_statusFromString(String)` (statique, privée)

Convertit la chaîne Supabase en `InvitationStatus`.
Insensible à la casse via `.toLowerCase()`. Retourne `pending` par défaut.

### `copyWith`

Pattern standard sans flag de suppression. `respondedAt` peut être mis à `null`
uniquement si la valeur courante est déjà `null` — le pattern classique ne permet
pas de le forcer à `null` explicitement depuis une valeur non nulle.

---

## Table Supabase associée

| Table | Colonnes écrites par `toMap` | Colonnes lues par `fromMap` |
|---|---|---|
| `invitations` | `event_id`, `invited_by_user_id`, `invited_user_email`, `invited_user_prenom`, `invited_user_nom`, `status` | Toutes + `id`, `created_at`, `responded_at` |

---

## Points d'attention

- La personne invitée n'est pas nécessairement un utilisateur de l'application —
  l'invitation se fait par email, pas par UID.
- `copyWith` ne permet pas de forcer `respondedAt` à `null` si elle est déjà
  définie (limitation du pattern). Une mise à `null` explicite nécessiterait
  un flag `clearRespondedAt` comme dans `event.dart`.
- Le statut est stocké en base comme chaîne (`status.name`) — `'pending'`,
  `'accepted'` ou `'declined'`. Toute renommée de l'enum sans migration de données
  casserait la désérialisation.