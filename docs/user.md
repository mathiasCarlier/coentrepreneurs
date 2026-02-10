Résumé de `user.dart`

But: Modèle applicatif représentant un utilisateur enrichi (données Firestore).

Points clés

- `UserRole` : enum { admin, adherent, invite } utilisé pour la logique d'autorisation.
- Conversion stockage/lecture : le rôle est persisté en texte (`'admin'`, `'adherent'`, `'invite'`).
- `toJson` / `fromJson` : méthodes utilitaires pour sérialisation/ désérialisation.

Conseils

- Si vous utilisez généralement `Timestamp` Firestore pour les dates, standardisez
  ce format dans toute l'application.
- Tests : vérifier la conversion `role` pour toutes les valeurs attendues.
