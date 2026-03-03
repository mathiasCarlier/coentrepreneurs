Résumé de `login_page.dart`

But: Écran de connexion — formulaire email/mot de passe, validation locale, appel à `AuthService.login`.

Points clés

- `_submit()` : valide le formulaire, appelle `AuthService.login`, redirige vers `/home`.
- Gestion d'état local : `_loading`, `_error`, `_showPassword`.
- Validation simple côté client (présence et format pour email, longueur pour password).
- Vérification du blocage utilisateur lors du login (si `blocked == true`, déconnexion immédiate).

Conseils

- Ne pas renvoyer de messages d'erreur détaillés côté client (sécurité); `AuthService` centralise la traduction des erreurs Supabase Auth.
- Pour améliorer UX, ajouter `FocusScope` pour naviguer entre les champs.
