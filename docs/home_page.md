Résumé de `home_page.dart`

But: Accueil principal de l'application — gestion de l'UI et du contrôle d'accès via les CGU et le statut d'approbation.

Points clés et parties complexes

- Vérification et affichage des CGU
  - Méthode: `_checkAndHandleCGU()`
  - Rôle: récupérer l'utilisateur courant (via `AuthService`), vérifier dans Supabase
    si la version actuelle des CGU a été acceptée et déclencher `_showCGUDialog()`
    si nécessaire.
  - Attention: appelée depuis `initState()`, elle effectue des opérations asynchrones
    et doit vérifier `mounted` avant d'appeler `setState`.

- Dialogue d'acceptation
  - Méthode: `_showCGUDialog(userId)`
  - Comportement: affiche `CGUAcceptanceDialog`, enregistre l'acceptation via
    `CGUService.acceptCGU()` et met à jour `approval_status` à `'pending'`
    dans la table `users`.
  - Affiche un SnackBar confirmant que la demande d'adhésion est en attente.

- Contrôle d'accès par `approval_status`
  - Pour les utilisateurs non-admin, le système vérifie `approval_status` via
    un stream de polling sur la table `users`.
  - Logique d'accès (inversée pour sécurité):
    - `rejected` → écran de refus (`_buildRejectedScreen`)
    - Tout sauf `approved` (y compris `null` et `pending`) → écran d'attente (`_buildPendingApprovalScreen`)
    - `approved` → contenu principal (`_buildMainContent`)
  - Cela garantit qu'un utilisateur sans `approval_status` défini ne peut pas
    accéder à l'application par défaut.

- Stream d'authentification
  - `StreamBuilder<User?>` écoute `auth.authStateChanges` fourni par `AuthService`.
  - Le builder doit gérer les états `waiting` et tenir compte de l'état
    `_cguCheckCompleted` (vérification asynchrone des CGU) avant d'afficher
    le contenu principal.

- Écran d'accès limité
  - `_buildAccessDeniedScreen(...)` propose une UI pour inviter l'utilisateur
    à lire/accepter les CGU (bouton qui relance `_showCGUDialog`).

Conseils

- Garder `currentCGUVersion` synchronisé (côté service) lors d'une MAJ des CGU.
- Tester le comportement lors de la restauration de l'application (cold start),
  pour s'assurer que la vérification des CGU s'exécute correctement.
- L'admin bypass le contrôle d'`approval_status` — seuls les utilisateurs
  non-admin sont soumis au workflow d'approbation.
