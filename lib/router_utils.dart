import 'package:supabase_flutter/supabase_flutter.dart';

// Détermine la redirection en fonction de l'état d'authentification.
// - Si l'utilisateur n'est pas connecté et tente d'accéder à une route
//   protégée, renvoyer la route de login.
// - Si l'utilisateur est connecté et tente d'accéder aux écrans d'auth
//   (`/login` ou `/signup`), renvoyer `/home` pour éviter les écrans d'auth
//   inutiles.
String? computeRedirect(dynamic auth, String path, [bool isPasswordRecovery = false]) {
  if (isPasswordRecovery) return '/reset-password';

  final publicRoutes = ['/login', '/signup', '/reset-password'];
  final isPublic = publicRoutes.contains(path);

  if (!auth.isSignedIn && !isPublic) return '/login';
  if (auth.isSignedIn && path == '/login') return '/home';

  return null;
}
