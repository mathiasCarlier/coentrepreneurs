# Résumé de `feedback_service.dart`

**But :** Service de gestion des retours d'expérience post-événement.
Couvre la création, la mise à jour, la lecture, les statistiques et la suppression
des feedbacks. Utilisé par `FeedbackPrompt` (widget) et potentiellement par une
page d'administration des retours.

---

## CRUD

### `createFeedback(...)`

Construit un objet `Feedback` avec `id: ''` (généré par Supabase), puis appelle
`feedback.toMap()` pour l'insertion. Les champs `createdAt` et `updatedAt` sont
initialisés à `DateTime.now()` mais ne sont pas inclus dans `toMap()` — ils sont
gérés par Supabase (valeurs par défaut côté base).

### `updateFeedback(feedbackId, ...)`

UPDATE ciblé sur les seuls champs modifiables : `what_you_liked`, `rating`,
`what_you_learned` + `updated_at` mis à jour manuellement en ISO 8601.
Ne modifie pas `user_id`, `event_id` ni les données utilisateur dénormalisées.

### `deleteFeedback(feedbackId)`

DELETE unitaire par `id`.

### `deleteEventFeedbacks(eventId)`

DELETE en masse sur tous les feedbacks d'un événement donné.
Utile pour nettoyer avant la suppression d'un événement.

---

## Lectures

| Méthode | Filtre | Retour |
|---|---|---|
| `getFeedback(feedbackId)` | `id` | `Feedback?` |
| `getUserEventFeedback(eventId, userId)` | `event_id` + `user_id` | `Feedback?` |
| `getEventFeedbacks(eventId)` | `event_id` + tri `created_at` DESC | `List<Feedback>` |
| `getEventFeedbacksStream(eventId)` | `event_id` (stream Realtime) | `Stream<List<Feedback>>` |
| `hasFeedback(eventId, userId)` | `event_id` + `user_id` | `bool` |

### `getEventFeedbacksStream`

Stream Supabase Realtime filtré sur `event_id`. Le tri par `createdAt` décroissant
est appliqué côté Dart via `..sort(...)` dans le `.map()` — le stream Supabase
ne supporte pas `.order()`.

### `hasFeedback`

Effectue un SELECT `id` (léger) et vérifie si la liste est non vide.
Utilisé par `FeedbackPrompt` pour déterminer si le formulaire doit être affiché
ou si l'utilisateur a déjà soumis un retour pour cet événement.

---

## Statistiques

### `getAverageRating(eventId)`

SELECT `rating` pour tous les feedbacks de l'événement.
Calcule la moyenne en Dart (boucle `for`). Retourne `0.0` si aucun feedback.

> Le calcul côté Dart charge tous les ratings en mémoire — acceptable pour
> des volumes associatifs, mais une fonction SQL `AVG` serait plus efficace
> à grande échelle.

### `getFeedbackCount(eventId)`

SELECT `id` et retourne `.length`. Pas d'agrégation SQL.

---

## Table Supabase

| Table | Opérations | Champs concernés |
|---|---|---|
| `feedbacks` | SELECT, INSERT, UPDATE, DELETE, stream Realtime | `id`, `event_id`, `user_id`, `user_email`, `user_prenom`, `user_nom`, `what_you_liked`, `rating`, `what_you_learned`, `created_at`, `updated_at` |

---

## Gestion des erreurs

Toutes les méthodes encapsulent les exceptions dans des `Exception` avec messages
français. Les succès sont loggués en mode debug via `debugPrint`. Les erreurs
sont propagées à l'appelant sans absorption silencieuse.