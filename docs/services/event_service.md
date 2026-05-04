Résumé de `event_service.dart`

But: Service de gestion des événements et inscriptions.

Points clés

- CRUD événements
  - `createEvent()`, `updateEvent()`, `deleteEvent()`
  - `getEvent(eventId)` : récupère un événement avec jointure registrations.

- Streams Realtime
  - `getAllEventsStream()` : double souscription sur `events` + `registrations`,
    reconstruit la liste complète via `asyncMap` à chaque changement.
  - `getUserEventsStream(userId)` : événements auxquels l'utilisateur est inscrit.

- Inscriptions
  - `registerUserToEvent()` / `unregisterUserFromEvent()`
  - `confirmUserPresence()` / `removePresenceConfirmation()`

- Statuts événement
  - `updateEventStatus()` : transitions `pending` → `started` → `finished`.

- Statistiques
  - `getEventStats()` : taux de remplissage, taux de confirmation, compteurs.

- Requêtes avancées
  - `searchEventsByTheme()` : recherche textuelle.
  - `getUpcomingEvents()` / `getPastEvents()` : filtrés par date.
  - `getUserConfirmedEvents()` : événements confirmés par un utilisateur.

- Utilitaires
  - `initializeDefaultEvents()` / `clearAllEvents()` : seeding et nettoyage.

Tables Supabase: `events`, `registrations`
Pattern: double stream pour synchroniser les changements des deux tables.
