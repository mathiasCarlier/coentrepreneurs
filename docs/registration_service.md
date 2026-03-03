Résumé de `registration_service.dart`

But: Service de gestion des inscriptions et participations aux événements.

Points clés

- Inscriptions
  - `registerUserToEvent(eventId, userId)` : crée une inscription.
  - `unregisterUserFromEvent()` : supprime l'inscription.
  - `isUserRegistered()` : vérifie si l'utilisateur est inscrit.

- Déclin
  - `declineEvent()` : upsert avec statut declined.
  - `cancelDecline()` : annule le déclin.

- Confirmation de présence
  - `confirmUserPresence()` / `removePresenceConfirmation()`
  - `isUserConfirmed()` : vérifie la confirmation.

- Collation
  - `saveCollationChoice()` / `removeCollationChoice()` : gestion des préférences
    alimentaires pour l'événement.

- Requêtes utilisateur
  - `getUserRegisteredEvents()` / `getUserRegisteredEventsStream()` : événements inscrits.
  - `getUserConfirmedEvents()` / `getUserConfirmedEventsStream()` : événements confirmés.

- Statistiques
  - `getRegisteredCount()` / `getConfirmedCount()` : compteurs par événement.
  - `getRegisteredUsers()` / `getConfirmedUsers()` : listes avec jointure users.

Table Supabase: `registrations` (avec jointure `users`)
Pattern: Futures + Streams, utilisation de `.inFilter()` pour requêtes complexes.
