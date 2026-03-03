Résumé de `admin_events_page.dart`

But: Interface complète de gestion des événements pour les administrateurs.

Points clés

- Liste des événements
  - Stream Realtime via `EventService.getAllEventsStream()`.
  - `_EventCard` : affichage compact avec thème, date, statut, jauge de capacité,
    nombre de confirmations.

- Création / Édition
  - `_EventFormDialog` : formulaire avec champs obligatoires (thème, date, lieu, capacité)
    et optionnels (description, image, fichier, lien).
  - Upload image/fichier via `StorageService`.

- Détails événement
  - `_EventDetailsSheet` : bottom sheet draggable avec toutes les infos.
  - `_ParticipantsSection` : liste des inscrits et confirmés avec données utilisateur.

- Cycle de vie
  - `_toggleEventStatus()` : transitions `pending` → `started` → `finished`.
  - Suppression avec dialog de confirmation.

- Bilan post-événement
  - `_SummaryDialog` : éditeur markdown pour le compte-rendu.
  - `updateEventSummary()` pour persister le bilan.

Tables Supabase: `events`, `registrations`
Services utilisés: `EventService`, `StorageService`
