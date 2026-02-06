Résumé de `home_page.dart`

But: Accueil principal de l'application — gestion de l'UI et du contrôle d'accès via les CGU.

Points clés et parties complexes

- Vérification et affichage des CGU
  - Méthode: `_checkAndHandleCGU()`
  - Rôle: récupérer l'utilisateur courant (via `AuthService`), vérifier en Firestore
    si la version actuelle des CGU a été acceptée et déclencher `_showCGUDialog()`
    si nécessaire.
  - Attention: appelée depuis `initState()`, elle effectue des opérations asynchrones
    et doit vérifier `mounted` avant d'appeler `setState`.

- Dialogue d'acceptation
  - Méthode: `_showCGUDialog(userId)`
  - Comportement: affiche `CGUAcceptanceDialog`, enregistre l'acceptation via
    `CGUService.acceptCGU()` et affiche des `SnackBar` en cas de succès/erreur.
  - `.then((accepted) { ... })` gère le cas où l'utilisateur refuse/ferme la dialog
    (déclenche `_handleCGURejection()` et la déconnexion).

- Stream d'authentification
  - `StreamBuilder<User?>` écoute `auth.authStateChanges` fourni par `AuthService`.
  - Le builder doit gérer les états `waiting` et tenir compte de l'état
    `_cguCheckCompleted` (vérification asynchrone des CGU) avant d'afficher
    le contenu principal.

- Écran d'accès limité
  - `_buildAccessDeniedScreen(...)` propose une UI pour inviter l'utilisateur
    à lire/accept les CGU (bouton qui reclenche `_showCGUDialog`).

Conseils

- Garder `currentCGUVersion` synchronisé (côté service) lors d'une MAJ des CGU.
- Tester le comportement lors de la restauration de l'application (cold start),
  pour s'assurer que la vérification des CGU s'exécute correctement.
