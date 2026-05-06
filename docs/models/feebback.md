# Résumé de `feedback.dart`

**But :** Modèle représentant le retour d'expérience d'un participant après une
rencontre terminée. Utilisé par `FeedbackPrompt` (widget) et le service associé
pour l'insertion et la lecture dans Supabase.

---

## Classe `Feedback`

### Champs

| Champ | Type | Colonne Supabase | Rôle |
|---|---|---|---|
| `id` | `String` | `id` | UUID généré par Supabase à l'insertion |
| `eventId` | `String` | `event_id` | Référence vers l'événement concerné |
| `userId` | `String` | `user_id` | Référence vers l'utilisateur auteur |
| `userEmail` | `String` | `user_email` | Email dénormalisé (snapshot) |
| `userPrenom` | `String` | `user_prenom` | Prénom dénormalisé (snapshot) |
| `userNom` | `String` | `user_nom` | Nom dénormalisé (snapshot) |
| `whatYouLiked` | `String` | `what_you_liked` | Ce que l'utilisateur a apprécié |
| `rating` | `int` | `rating` | Note (valeurs attendues non contraintes côté modèle) |
| `whatYouLearned` | `String` | `what_you_learned` | Ce que l'utilisateur a appris |
| `createdAt` | `DateTime` | `created_at` | Date de création (gérée par Supabase) |
| `updatedAt` | `DateTime` | `updated_at` | Date de mise à jour (gérée par Supabase) |

> Les champs `userEmail`, `userPrenom` et `userNom` sont dénormalisés :
> ils copient l'état de l'utilisateur au moment du feedback. Cela préserve
> les données si le profil est modifié ultérieurement.

---

## Méthodes

### `toMap()`

Sérialisation pour l'**insertion** Supabase uniquement.
N'inclut pas `id`, `created_at` ni `updated_at` — ces champs sont générés
automatiquement par la base.

### `Feedback.fromMap(Map)`

Désérialisation depuis une réponse Supabase.
`createdAt` et `updatedAt` utilisent `DateTime.parse` avec fallback sur
`DateTime.now().toIso8601String()` si le champ est absent — évite une exception
mais masque silencieusement une donnée manquante.

### `copyWith`

Pattern standard de copie immuable sans flag de suppression (aucun champ
nullable ne nécessite d'être mis à `null` explicitement).

---

## Table Supabase associée

| Table | Colonnes écrites par `toMap` | Colonnes lues par `fromMap` |
|---|---|---|
| `feedbacks` | `event_id`, `user_id`, `user_email`, `user_prenom`, `user_nom`, `what_you_liked`, `rating`, `what_you_learned` | Toutes les colonnes ci-dessus + `id`, `created_at`, `updated_at` |

---

## Points d'attention

- Le champ `rating` est un `int` sans contrainte de plage côté modèle — la
  validation (ex. 1 à 5) doit être effectuée dans le widget ou le service.
- `DateTime.parse` dans `fromMap` lève une exception si la chaîne est mal
  formée. Le fallback `?? DateTime.now().toIso8601String()` ne protège que
  contre une valeur `null`, pas contre un format invalide.
- La dénormalisation des infos utilisateur (`userEmail`, `userPrenom`, `userNom`)
  implique que les feedbacks existants ne reflètent pas les changements de profil
  ultérieurs — comportement voulu pour l'audit.