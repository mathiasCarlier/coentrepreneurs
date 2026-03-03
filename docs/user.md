Résumé de `user.dart`

But: Modèle applicatif représentant un utilisateur enrichi (données table `users`).

Points clés

- `UserRole` : enum { admin, adherent, invite } utilisé pour la logique d'autorisation.
- Conversion stockage/lecture : le rôle est persisté en texte (`'admin'`, `'adherent'`, `'invite'`).
- `toJson` / `fromJson` : méthodes utilitaires pour sérialisation/désérialisation.
- Champs optionnels: `photoUrl`, `companyName`, `skills`, `professionalAddress`,
  `website`, `shareProInfo` pour le profil professionnel.

Conseils

- Standardiser le format des dates (ISO 8601 string) dans toute l'application.
- Tests : vérifier la conversion `role` pour toutes les valeurs attendues.
