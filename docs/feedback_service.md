Résumé de `feedback_service.dart`

But: Service de collecte et analyse des retours post-événement.

Points clés

- CRUD
  - `createFeedback()` : insert avec détails utilisateur (email, prénom, nom).
  - `updateFeedback()` : met à jour note, avis, apprentissages.
  - `deleteFeedback()` / `deleteEventFeedbacks()` : suppression unitaire ou par événement.

- Requêtes
  - `getFeedback(feedbackId)` : feedback unique.
  - `getUserEventFeedback(eventId, userId)` : feedback d'un utilisateur pour un événement.
  - `getEventFeedbacks()` : tous les feedbacks d'un événement.
  - `getEventFeedbacksStream()` : stream Realtime avec tri par date.
  - `hasFeedback()` : vérifie si un feedback existe.

- Statistiques
  - `getAverageRating()` : note moyenne (1-5).
  - `getFeedbackCount()` : nombre de feedbacks par événement.

Table Supabase: `feedbacks`
Champs: `event_id`, `user_id`, `user_email`, `user_prenom`, `user_nom`,
`what_you_liked`, `rating` (1-5), `what_you_learned`, `created_at`, `updated_at`
