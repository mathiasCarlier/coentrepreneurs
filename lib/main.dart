import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

import 'package:coentrepreneurs/services/auth_service.dart';
import 'package:coentrepreneurs/router_utils.dart';
import 'package:coentrepreneurs/pages/login_page.dart';
import 'package:coentrepreneurs/pages/signup_page.dart';
import 'package:coentrepreneurs/pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('INIT FIREBASE...');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('FIREBASE OK');
  } catch (e) {
    print('FIREBASE ERROR: $e');
  }
  runApp(const App());
}

// NOTE: `main` initialise Firebase et démarre l'app. En environnement de
// production, on pourrait gérer les erreurs Firebase plus finement (écran
// d'erreur, retry, logging), ici un simple `print` est utilisé pour debug.

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthService _authService;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _router = _createRouter(_authService);
  }

  // NOTE: l'instance `AuthService` est créée ici et fournie via `Provider`.
  // Le routeur utilise `GoRouterRefreshStream` lié à `authStateChanges`
  // pour recalculer les redirections automatiquement quand l'état change.

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Provider<AuthService>.value(
      value: _authService,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Coentrepreneurs',
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        routerConfig: _router,
      ),
    );
  }
}

ThemeData _buildLightTheme() {
  const seed = Color(0xFF2E6AE6);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  );
  final textTheme = GoogleFonts.interTextTheme();

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      centerTitle: false,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerHighest,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

ThemeData _buildDarkTheme() {
  const seed = Color(0xFF2E6AE6);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  );
  final textTheme = GoogleFonts.interTextTheme(
    ThemeData(brightness: Brightness.dark).textTheme,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      centerTitle: false,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: scheme
          .surfaceContainerHighest, // remplacer surfaceContainerLow si nécessaire
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

GoRouter _createRouter(AuthService authService) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(authService.authStateChanges),
    redirect: (context, state) {
      // Utilise la fonction testable computeRedirect
      // Utiliser state.uri.path pour récupérer le chemin sans query/fragment
      return computeRedirect(authService, state.uri.path);
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
}
