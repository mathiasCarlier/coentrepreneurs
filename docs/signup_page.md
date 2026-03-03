Résumé de `signup_page.dart`

But: Écran d'inscription — collecte des informations utilisateur et création du compte via `AuthService.signup`.

Points clés

- `_submit()` : effectue les validations (matching des mots de passe, champs requis) et appelle `AuthService.signup`.
- Rôle par défaut: `invite` (l'utilisateur doit être approuvé par un admin).
- `approval_status` est défini à `'pending'` lors de l'inscription.
- Après création, redirige vers `/home` où l'écran d'attente d'approbation s'affiche.

Conseils

- Valider plus strictement le format du téléphone si nécessaire.
- Le nouvel utilisateur ne pourra accéder à l'app qu'après approbation admin
  (via la page notifications).
