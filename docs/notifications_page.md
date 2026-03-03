Résumé de `notifications_page.dart`

But: Page de notifications avec 3 onglets : Adhésions, Rencontres, Messages.
Affichage adapté selon le rôle (admin vs utilisateur).

Points clés et parties complexes

- Onglet Adhésions (admin)
  - Affiche les utilisateurs en attente d'approbation (`approval_status: 'pending'`).
  - Actions: Approuver (role → adherent, status → approved) ou Refuser (status → rejected, blocked → true).
  - Données chargées via Future (`_fetchPendingUsers`) et non via stream Realtime,
    pour garantir le rafraîchissement immédiat après approbation/rejet.
  - Après chaque action, `_loadUsers()` recharge les données et déclenche `setState`.

- Onglet Adhésions (utilisateur)
  - Affiche les nouveaux membres approuvés dans les 7 derniers jours.
  - Bouton "Marquer comme vu" avec persistance dans `read_new_member_ids` (table users).

- Onglet Rencontres
  - Stream Realtime sur la table `events`.
  - Filtre: événements créés aujourd'hui ou après, dont la date n'est pas passée.
  - Lecture/non-lecture persistée dans `read_notification_event_ids`.

- Onglet Messages
  - Stream Realtime sur la table `messages` (filtre `published == true`).
  - Lecture/non-lecture persistée dans `read_notification_message_ids`.

- Badges de comptage
  - Adhésions: utilise les données en cache (`_pendingUsers` / `_approvedMembers`).
  - Rencontres et Messages: StreamBuilder sur les streams Realtime respectifs.

Tables Supabase utilisées

| Table | Usage |
|---|---|
| `users` | Pending/approved members, read IDs, rôle admin |
| `events` | Nouveaux événements |
| `messages` | Messages publiés |

Architecture: données utilisateurs = Future rechargeable / événements et messages = Streams Realtime.
