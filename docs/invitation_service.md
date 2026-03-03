Résumé de `invitation_service.dart`

But: Service de gestion du cycle de vie des invitations aux événements.

Points clés

- Création
  - `createInvitation()` : invitation simple.
  - `createInvitationsWithUsers()` : batch d'invitations, avec auto-inscription
    si l'utilisateur existe déjà dans la table `users`.

- Réception / Envoi
  - `getReceivedInvitations()` / `getReceivedInvitationsStream()` : par email du destinataire.
  - `getSentInvitations()` : par user_id de l'expéditeur.
  - `getEventInvitations()` / `getEventInvitationsStream()` : par event_id.

- Réponse
  - `acceptInvitation()` : statut → accepted, timestamp responded_at.
  - `declineInvitation()` : statut → declined.

- Statistiques
  - `getPendingInvitationsCount()` / `getAcceptedInvitationsCount()`
  - `hasPendingInvitation()` / `hasAcceptedInvitation()`

- Nettoyage
  - `deleteInvitation()` / `deleteEventInvitations()`

Table Supabase: `invitations`
Tables liées: `users` (lookup email), `registrations` (auto-insert à l'acceptation)
Statuts: `pending` → `accepted` | `declined`
