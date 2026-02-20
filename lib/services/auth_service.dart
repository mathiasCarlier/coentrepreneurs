import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:coentrepreneurs/models/user.dart' as user_model;

// Service d'authentification et d'interface avec FirebaseAuth / Firestore.
// Responsabilités principales :
// - exposer un `authStateChanges` stream qui renvoie un `User?` application-level
//   construit à partir de l'utilisateur Firebase + données Firestore,
// - fournir des méthodes `login`, `signup`, `logout` utilisées par l'UI,
// - centraliser la conversion d'erreurs Firebase en messages en français.
class AuthService {
  AuthService({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _auth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final firebase_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Stream qui émet les changements d'état d'authentification
  Stream<user_model.User?> get authStateChanges {
    // On écoute FirebaseAuth puis on enrichit chaque `firebaseUser` avec
    // les données utilisateur stockées dans Firestore. `asyncMap` est utilisé
    // car la récupération Firestore est asynchrone.
    // Remarque : toute exception ici est capturée et un `User` minimal peut
    // être renvoyé pour que l'UI conserve un état cohérent.
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      try {
        final userData = await _getUserData(firebaseUser.uid);
        if (userData != null) {
          return user_model.User(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            nom: userData['nom'] ?? '',
            prenom: userData['prenom'] ?? '',
            phone: userData['phone'] ?? '',
            role: _parseRole(userData['role']),
          );
        }
        // Si les données Firestore ne sont pas disponibles, créer un utilisateur minimal
        return user_model.User(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          nom: '',
          prenom: '',
          phone: '',
          role: user_model.UserRole.invite,
        );
      } catch (e) {
        debugPrint('Erreur lors de la récupération des données utilisateur: $e');
        // Retourner un utilisateur avec les données de base même en cas d'erreur
          return user_model.User(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          nom: '',
          prenom: '',
          phone: '',
          role: user_model.UserRole.invite,
        );
      }
    });
  }

  /// Récupère l'utilisateur actuel
  Future<user_model.User?> get currentUser async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    try {
      final userData = await _getUserData(firebaseUser.uid);
        if (userData != null) {
        return user_model.User(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          nom: userData['nom'] ?? '',
          prenom: userData['prenom'] ?? '',
          phone: userData['phone'] ?? '',
          role: _parseRole(userData['role']),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'utilisateur actuel: $e');
    }
    return null;
  }

  /// Retourne vrai si un utilisateur est connecté (synchrone)
  bool get isSignedIn => _auth.currentUser != null;

  /// Connexion avec email et mot de passe
  Future<user_model.User?> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user == null) {
        throw Exception('La connexion a échoué.');
      }

      try {
        final userData = await _getUserData(result.user!.uid);
        if (userData != null) {
          return user_model.User(
            uid: result.user!.uid,
            email: result.user!.email ?? '',
            nom: userData['nom'] ?? '',
            prenom: userData['prenom'] ?? '',
            phone: userData['phone'] ?? '',
            role: _parseRole(userData['role']),
          );
        }
      } catch (e) {
        debugPrint('Impossible de récupérer les données Firestore: $e');
        // Retourner un utilisateur minimal si Firestore est indisponible
      }

      return user_model.User(
        uid: result.user!.uid,
        email: result.user!.email ?? '',
        nom: '',
        prenom: '',
        phone: '',
        role: user_model.UserRole.invite,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Erreur de connexion: $e';
    }
  }

  /// Inscription avec email, mot de passe et informations utilisateur
  Future<user_model.User?> signup({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String phone,
    user_model.UserRole role = user_model.UserRole.invite,
  }) async {
    try {
      // Validation des entrées
      if (email.isEmpty || password.isEmpty || nom.isEmpty || prenom.isEmpty || phone.isEmpty) {
        throw 'Tous les champs sont obligatoires.';
      }

      if (password.length < 6) {
        throw 'Le mot de passe doit contenir au moins 6 caractères.';
      }

      // Créer l'utilisateur Firebase
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user == null) {
        throw 'La création du compte a échoué.';
      }

      // Sauvegarder les informations utilisateur dans Firestore
      final user = user_model.User(
        uid: result.user!.uid,
        email: result.user!.email ?? email,
        nom: nom.trim(),
        prenom: prenom.trim(),
        phone: phone.trim(),
        role: role,
      );

      await _firestore.collection('users').doc(result.user!.uid).set(
        {
          'uid': user.uid,
          'email': user.email,
          'nom': user.nom,
          'prenom': user.prenom,
          'phone': user.phone,
          'role': user.role.toString().split('.').last,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Erreur d\'inscription: $e';
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Erreur lors de la déconnexion: $e';
    }
  }

  /// Récupère les données utilisateur depuis Firestore
  Future<Map<String, dynamic>?> _getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des données: $e');
      return null;
    }
  }

  /// Convertit une chaîne en UserRole
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

  /// Gère les exceptions Firebase Auth et les convertit en messages français
  static String _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Utilisateur non trouvé. Vérifiez votre email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'invalid-email':
        return 'Email invalide.';
      case 'user-disabled':
        return 'Cet utilisateur a été désactivé.';
      case 'too-many-requests':
        return 'Trop de tentatives de connexion. Réessayez plus tard.';
      case 'operation-not-allowed':
        return 'L\'opération n\'est pas autorisée.';
      case 'email-already-in-use':
        return 'Cet email est déjà associé à un compte.';
      case 'weak-password':
        return 'Le mot de passe est trop faible. Utilisez au moins 6 caractères.';
      case 'invalid-credential':
        return 'Les identifiants fournis sont invalides.';
      case 'network-request-failed':
        return 'Erreur réseau. Vérifiez votre connexion internet.';
      default:
        return 'Erreur d\'authentification: ${e.message ?? 'Inconnue'}';
    }
  }

  void dispose() {
    // Nothing to dispose for FirebaseAuth instance.
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  // Helper utilitaire pour intégrer un Stream (ex: auth state) avec GoRouter.
  // GoRouter attend un [Listenable] pour déclencher la redirection; cette
  // classe adapte un Stream en ChangeNotifier en réémettant `notifyListeners`
  // à chaque événement du stream.
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
