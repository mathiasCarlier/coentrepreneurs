# Résumé de `invitation_service.dart`

**But :** Service de gestion du cycle de vie complet des invitations aux événements.
Gère la création, la lecture, la réponse, les statistiques et la suppression.
Utilisé par `EventGuestsSection` (widget) et potentiellement par d'autres pages
de gestion d'événements.

---

## Création

### `createInvitation(...)`

Création simple d'une invitation. Construit un objet `Invitation` avec
`status: pending` et `id: ''`, puis l'insère via `invitation.toMap()`.

### `createInvitationsWithUsers(...)`

Création en batch avec **auto-inscription** à l'événement si l'invité a déjà
un compte. Traite les invitations séquentiellement (pas de `Future.wait`).

Pour chaque invitation dans la liste :
1. Valide que `email`, `prenom` et `nom` sont non vides
2. INSERT dans `invitations` directement (sans passer par le modèle)
3. Cherche un compte existant via `users.email == email`
4. Si trouvé → **UPSERT** dans `registrations` avec `status: 'registered'`
   (évite les doublons si l'utilisateur est déjà inscrit)

> La recherche par email est insensible à la casse grâce au `.toLowerCase().trim()`
> appliqué avant la requête. L'upsert dans `registrations` suppose une contrainte
> unique sur `(event_id, user_id)`.

---

## Lectures

| Méthode | Filtre | Type retour |
|---|---|---|
| `getReceivedInvitations(email)` | `invited_user_email` | `Future<List<Invitation>>` |
| `getReceivedInvitationsStream(email)` | `invited_user_email` (Realtime) | `Stream<List<Invitation>>` tri DESC |
| `getEventInvitationsStream(eventId)` | `event_id` (Realtime) | `Stream<List<Invitation>>` tri ASC |
| `getSentInvitations(userId)` | `invited_by_user_id` | `Future<List<Invitation>>` |
| `getEventInvitations(eventId)` | `event_id` | `Future<List<Invitation>>` |
| `getInvitation(invitationId)` | `id` + `.maybeSingle()` | `Future<Invitation?>` |

> Les streams reçus (`getReceivedInvitationsStream`) sont triés par `createdAt`
> **décroissant** (plus récent en premier), tandis que les streams par événement
> (`getEventInvitationsStream`) sont triés **croissant** (ordre chronologique d'invitation).

---

## Réponse à une invitation

### `acceptInvitation(invitationId)`

UPDATE `status → 'accepted'` + `responded_at → now()`.
N'inscrit **pas** automatiquement l'utilisateur à l'événement — cette logique
est gérée en amont dans `createInvitationsWithUsers` ou côté widget.

### `declineInvitation(invitationId)`

UPDATE `status → 'declined'` + `responded_at → now()`.

---

## Statistiques et vérifications

| Méthode | Filtre | Retour |
|---|---|---|
| `getPendingInvitationsCount(email)` | `invited_user_email` + `status == 'pending'` | `int` |
| `getAcceptedInvitationsCount(eventId)` | `event_id` + `status == 'accepted'` | `int` |
| `hasPendingInvitation(eventId, email)` | `event_id` + `email` + `status == 'pending'` | `bool` |
| `hasAcceptedInvitation(eventId, email)` | `event_id` + `email` + `status == 'accepted'` | `bool` |

Toutes les vérifications font un SELECT `id` léger et vérifient si la liste
est non vide — pas d'agrégation SQL.

---

## Suppression

| Méthode | Cible |
|---|---|
| `deleteInvitation(invitationId)` | DELETE par `id` |
| `deleteEventInvitations(eventId)` | DELETE en masse par `event_id` |

---

## Tables Supabase

| Table | Opérations | Champs concernés |
|---|---|---|
| `invitations` | SELECT, INSERT, UPDATE, DELETE, stream Realtime | `id`, `event_id`, `invited_by_user_id`, `invited_user_email`, `invited_user_prenom`, `invited_user_nom`, `status`, `created_at`, `responded_at` |
| `users` | SELECT (lookup email) | `id`, `email` |
| `registrations` | UPSERT | `event_id`, `user_id`, `status` |

---

## Gestion des erreurs

Toutes les méthodes propagent les exceptions encapsulées dans `Exception` avec
messages français. `createInvitationsWithUsers` logue chaque étape en debug
(`debugPrint`) pour faciliter le diagnostic en développement.