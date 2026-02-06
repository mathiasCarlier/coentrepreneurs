Résumé de `signup_page.dart`

But: Écran d'inscription — collecte des informations utilisateur et création du compte via `AuthService.signup`.

Points clés

- `_submit()` : effectue les validations (matching des mots de passe, champs requis) et appelle `AuthService.signup`.
- `UserRole` sélectionnable via `_selectedRole` (par défaut `adherent`).
- Après création, redirige vers `/home`.

Conseils

- Valider plus strictement le format du téléphone si nécessaire.
- Gérer les cas où Firestore échoue après création Firebase (rollback si nécessaire).
