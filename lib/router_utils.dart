// Détermine la redirection en fonction de l'état d'authentification.
// - Si l'utilisateur n'est pas connecté et tente d'accéder à une route
//   protégée, renvoyer la route de login.
// - Si l'utilisateur est connecté et tente d'accéder aux écrans d'auth
//   (`/login` ou `/signup`), renvoyer `/home` pour éviter les écrans d'auth
//   inutiles.
String? computeRedirect(dynamic authService, String location) {
  final loggedIn = (authService?.isSignedIn ?? false);
  final goingToAuth = location == '/login' || location == '/signup';

  if (!loggedIn && !goingToAuth) return '/login';
  if (loggedIn && goingToAuth) return '/home';
  return null;
}
