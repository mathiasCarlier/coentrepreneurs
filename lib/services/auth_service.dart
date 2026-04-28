import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:coentrepreneurs/models/user.dart' as user_model;

// Service d'authentification — Supabase Auth + table public.users.
// Interface publique :
// - authStateChanges stream → User? enrichi depuis la table users
// - login(), signup(), logout(), sendPasswordResetEmail()
// - isSignedIn (synchrone)
class AuthService {
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Stream qui émet les changements d'état d'authentification.
  /// Chaque événement Supabase Auth est enrichi avec les données de la table users.
  Stream<user_model.User?> get authStateChanges {
  return _supabase.auth.onAuthStateChange.asyncMap((event) async {
    // ✅ Ne pas traiter la session recovery comme une connexion normale
    if (event.event == AuthChangeEvent.passwordRecovery) return null;
    
    final session = event.session;
    if (session == null) return null;
    return await _buildUser(session.user);
  });
}

  /// Stream brut des événements auth (pour détecter passwordRecovery).
  Stream<AuthChangeEvent> get authEventChanges {
    return _supabase.auth.onAuthStateChange.map((event) => event.event);
  }

  /// Récupère l'utilisateur actuel (asynchrone).
  Future<user_model.User?> get currentUser async {
    final supabaseUser = _supabase.auth.currentUser;
    if (supabaseUser == null) return null;
    return await _buildUser(supabaseUser);
  }

  /// Retourne vrai si un utilisateur est connecté (synchrone).
  bool get isSignedIn => _supabase.auth.currentSession != null;

  /// Connexion avec email et mot de passe.
  Future<user_model.User?> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        throw Exception('La connexion a échoué.');
      }

      final userData = await _getUserData(response.user!.id);
      if (userData != null && userData['blocked'] == true) {
        await _supabase.auth.signOut();
        throw 'Votre accès à l\'application a été bloqué par un administrateur.';
      }

      return await _buildUser(response.user!);
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      rethrow;
    }
  }

  /// Inscription avec email, mot de passe et informations utilisateur.
  Future<user_model.User?> signup({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String phone,
    user_model.UserRole role = user_model.UserRole.invite,
  }) async {
    try {
      if (email.isEmpty || password.isEmpty || nom.isEmpty || prenom.isEmpty || phone.isEmpty) {
        throw 'Tous les champs sont obligatoires.';
      }
      if (password.length < 6) {
        throw 'Le mot de passe doit contenir au moins 6 caractères.';
      }

      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        throw 'La création du compte a échoué.';
      }

      // Upsert : le trigger crée déjà une ligne minimale, on complète
      await _supabase.from('users').upsert({
        'id': response.user!.id,
        'email': email.trim(),
        'nom': nom.trim(),
        'prenom': prenom.trim(),
        'phone': phone.trim(),
        'role': role.name,
        'approval_status': 'pending',
      });

      return user_model.User(
        uid: response.user!.id,
        email: email.trim(),
        nom: nom.trim(),
        prenom: prenom.trim(),
        phone: phone.trim(),
        role: role,
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Erreur d\'inscription: $e';
    }
  }

  /// Envoie un email de réinitialisation du mot de passe.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Erreur lors de l\'envoi de l\'email: $e';
    }
  }

  /// Déconnexion.
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw 'Erreur lors de la déconnexion: $e';
    }
  }

  // --- Helpers privés ---

  Future<user_model.User?> _buildUser(User supabaseUser) async {
    try {
      final data = await _getUserData(supabaseUser.id);
      if (data != null) {
        return user_model.User(
          uid: supabaseUser.id,
          email: supabaseUser.email ?? '',
          nom: data['nom'] ?? '',
          prenom: data['prenom'] ?? '',
          phone: data['phone'] ?? '',
          role: _parseRole(data['role']),
          photoUrl: data['photo_url'],
          companyName: data['company_name'],
          skills: data['skills'],
          professionalAddress: data['professional_address'],
          website: data['website'],
          shareProInfo: data['share_pro_info'] ?? false,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur lors de la récupération des données utilisateur: $e');
    }
    return user_model.User(
      uid: supabaseUser.id,
      email: supabaseUser.email ?? '',
      nom: '',
      prenom: '',
      phone: '',
      role: user_model.UserRole.invite,
    );
  }

  Future<Map<String, dynamic>?> _getUserData(String uid) async {
    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('id', uid)
          .maybeSingle();
      return data;
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur lors de la récupération des données: $e');
      return null;
    }
  }

  static user_model.UserRole _parseRole(String? roleStr) {
    switch (roleStr) {
      case 'admin':
        return user_model.UserRole.admin;
      case 'adherent':
        return user_model.UserRole.adherent;
      case 'invite':
      default:
        return user_model.UserRole.invite;
    }
  }

  static String _handleAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
      return 'Email ou mot de passe incorrect.';
    } else if (msg.contains('email not confirmed')) {
      return 'Veuillez confirmer votre email avant de vous connecter.';
    } else if (msg.contains('user already registered') || msg.contains('already been registered')) {
      return 'Cet email est déjà associé à un compte.';
    } else if (msg.contains('password should be at least')) {
      return 'Le mot de passe est trop faible. Utilisez au moins 6 caractères.';
    } else if (msg.contains('unable to validate email address')) {
      return 'Email invalide.';
    } else if (msg.contains('too many requests')) {
      return 'Trop de tentatives de connexion. Réessayez plus tard.';
    } else if (msg.contains('network')) {
      return 'Erreur réseau. Vérifiez votre connexion internet.';
    }
    return 'Erreur d\'authentification: ${e.message}';
  }

  void dispose() {}
}

class GoRouterRefreshStream extends ChangeNotifier {
  // Helper utilitaire pour intégrer un Stream (ex: auth state) avec GoRouter.
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
