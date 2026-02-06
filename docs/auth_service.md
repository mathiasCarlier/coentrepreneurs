Résumé de `auth_service.dart`

But: Service d'authentification centralisé qui combine FirebaseAuth et Firestore.

Points clés et parties complexes

- `authStateChanges`:
  - Utilise `_auth.authStateChanges().asyncMap(...)` pour convertir le
    `firebase_auth.User` en objet `User` de l'application en enrichissant
    avec les données Firestore (nom, prénom, rôle...).
  - Les opérations Firestore sont asynchrones et peuvent échouer; le stream
    protège l'UI en renvoyant un `User` minimal si nécessaire.

- `currentUser`:
  - Méthode asynchrone qui retourne l'utilisateur enrichi si présent.
  - Utilisée par l'UI lors du démarrage pour vérifier l'état et effectuer
    des actions (ex: CGU).

- `login` / `signup`:
  - Gestion des erreurs FirebaseAuthException converties en messages
    utilisateur en français via `_handleAuthException`.
  - `signup` écrit également un document `users/{uid}` dans Firestore.

- `GoRouterRefreshStream`:
  - Adaptateur qui convertit un `Stream` en `ChangeNotifier` pour permettre
    à `GoRouter` de se re-router automatiquement quand l'auth state change.

Conseils

- Ne pas exposer `_auth` ou `_firestore` directement si vous voulez
  centraliser la logique (déjà respecté ici).
- Tests: simuler FirebaseAuth et Firestore pour vérifier les chemins d'erreur
  et la conversion des rôles.
