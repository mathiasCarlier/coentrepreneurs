String? computeRedirect(dynamic authService, String location) {
  final loggedIn = (authService?.isSignedIn ?? false);
  final goingToAuth = location == '/login' || location == '/signup';

  if (!loggedIn && !goingToAuth) return '/login';
  if (loggedIn && goingToAuth) return '/home';
  return null;
}
