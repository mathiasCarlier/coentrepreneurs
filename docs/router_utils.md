Résumé de `router_utils.dart`

But: Logique de redirection dépendant de l'état d'authentification.

Points clés

- `computeRedirect(authService, location)`
  - Si l'utilisateur n'est pas connecté et tente d'accéder à une route protégée,
    renvoie `/login`.
  - Si l'utilisateur est connecté et tente d'accéder aux pages d'auth (`/login`,
    `/signup`) renvoie `/home` pour éviter d'afficher des écrans d'auth inutiles.

Conseils

- Garder cette logique simple pour éviter des boucles de redirection.
- Pour des règles plus fines (rôles, permissions), centraliser la logique
  et étendre `computeRedirect` en conséquence.
