Résumé de `cgu_acceptance.dart`

But: Modèle pour représenter l'acceptation des CGU par utilisateur.

Points clés

- Champs : `userId`, `hasAccepted`, `acceptedDate`, `cguVersion`.
- `toMap` / `fromMap` utilisent une chaîne ISO pour la date (`toIso8601String`),
  assurez-vous que `CGUService` lit/écrit en cohérence (string vs Timestamp).

Conseils

- Pour l'audit, vous pouvez stocker une collection d'historique au lieu d'écraser
  le document si vous avez besoin d'un trail des acceptations.
