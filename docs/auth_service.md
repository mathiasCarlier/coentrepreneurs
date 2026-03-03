Résumé de `auth_service.dart`

But: Service d'authentification centralisé qui combine Supabase Auth et la table `users`.

Points clés et parties complexes

- `authStateChanges`:
  - Utilise `_supabase.auth.onAuthStateChange.asyncMap(...)` pour convertir le
    user Supabase Auth en objet `User` de l'application en enrichissant
    avec les données de la table `users` (nom, prénom, rôle...).
  - Les opérations Supabase sont asynchrones et peuvent échouer; le stream
    protège l'UI en renvoyant un `User` minimal si nécessaire.

- `currentUser`:
  - Méthode asynchrone qui retourne l'utilisateur enrichi si présent.
  - Utilisée par l'UI lors du démarrage pour vérifier l'état et effectuer
    des actions (ex: CGU).

- `login`:
  - Gestion des erreurs AuthException converties en messages
    utilisateur en français via `_handleAuthException`.
  - Vérifie si l'utilisateur est bloqué (`blocked == true`) et déconnecte
    automatiquement avec message d'erreur explicite.

- `signup`:
  - Crée le compte via Supabase Auth puis upsert dans la table `users`.
  - Définit `role: 'invite'` et `approval_status: 'pending'` par défaut.
  - Le nouvel utilisateur doit être approuvé par un admin avant d'accéder
    à l'application.

- Workflow d'approbation des nouveaux utilisateurs:
  1. Inscription → `role: invite`, `approval_status: pending`
  2. Acceptation CGU → `approval_status` reste `pending`
  3. Admin approuve → `approval_status: approved`, `role: adherent`
  4. Admin refuse → `approval_status: rejected`, `blocked: true`

- `GoRouterRefreshStream`:
  - Adaptateur qui convertit un `Stream` en `ChangeNotifier` pour permettre
    à `GoRouter` de se re-router automatiquement quand l'auth state change.

Conseils

- Ne pas exposer `_supabase` directement si vous voulez
  centraliser la logique (déjà respecté ici).
- Tests: simuler Supabase Auth et la table users pour vérifier les chemins d'erreur
  et la conversion des rôles.
