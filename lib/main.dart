import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:sentry_flutter/sentry_flutter.dart';

import 'supabase_config.dart';

import 'package:coentrepreneurs/services/auth_service.dart';
import 'package:coentrepreneurs/services/theme_service.dart';
import 'package:coentrepreneurs/router_utils.dart';
import 'package:coentrepreneurs/pages/login_page.dart';
import 'package:coentrepreneurs/pages/signup_page.dart';
import 'package:coentrepreneurs/pages/home_page.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      // Remplacer par le DSN de votre projet Sentry (sentry.io > Settings > DSN)
      options.dsn = const String.fromEnvironment(
        'SENTRY_DSN',
        defaultValue: '',
      );
      // N'envoie les erreurs qu'en production
      options.environment = kDebugMode ? 'debug' : 'production';
      // Capture 20 % des transactions pour les performances
      options.tracesSampleRate = kDebugMode ? 0.0 : 0.2;
    },
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();
      // Sur Safari, google_fonts peut échouer à charger les fonts en réseau.
      // On désactive le fetch runtime pour éviter le texte invisible.
      if (kIsWeb) {
        GoogleFonts.config.allowRuntimeFetching = false;
      }
      await initializeDateFormatting('fr_FR');
      if (kDebugMode) debugPrint('INIT SUPABASE...');
      try {
        await Supabase.initialize(
          url: SupabaseConfig.url,
          anonKey: SupabaseConfig.anonKey,
        );
        if (kDebugMode) debugPrint('SUPABASE OK');
      } catch (e) {
        if (kDebugMode) debugPrint('SUPABASE ERROR: $e');
      }
      runApp(const App());
    },
  );
}

// NOTE: `main` initialise Supabase et démarre l'app. En environnement de
// production, on pourrait gérer les erreurs Supabase plus finement (écran
// d'erreur, retry, logging).

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeNotifier>(create: (_) => ThemeNotifier()),
        Provider<AuthService>.value(value: _authService),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, _) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Coentrepreneurs',
            locale: const Locale('fr', 'FR'),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('fr', 'FR')],
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: themeNotifier.mode,
            routerConfig: _router,
          );
        },
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
  final baseTextTheme = GoogleFonts.interTextTheme();
  final textTheme = baseTextTheme.apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
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
      color: scheme.surfaceContainerHighest,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      // Make hint and label more visible in light mode
      hintStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.8)),
      labelStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.9)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // Ensure button text is readable on colored background
        foregroundColor: Colors.white,
        backgroundColor: scheme.primary,
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
  ).apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
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