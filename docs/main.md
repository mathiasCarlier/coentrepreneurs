Résumé de `main.dart`

But: Point d'entrée de l'application, initialisation Supabase, configuration du thème et du routeur.

Points clés

- `main()` : appelle `Supabase.initialize()` avec l'URL et la clé anonyme du projet.
- `AuthService` est fourni via `Provider` à la racine.
- `GoRouter` : utilise `GoRouterRefreshStream(authStateChanges)` et `computeRedirect` pour gérer les redirections basées sur l'auth state.
- Thèmes : `_buildLightTheme` et `_buildDarkTheme` centralisent le style de l'application.

Conseils

- Gérer explicitement les erreurs d'initialisation Supabase (écran d'erreur, retry).
- Pour tests, injecter des implémentations mock d'`AuthService`.
