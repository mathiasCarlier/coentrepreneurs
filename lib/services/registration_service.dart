// services/registration_service.dart - CORRIGÉ

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coentrepreneurs/models/event.dart';
import 'package:coentrepreneurs/models/user.dart' as user_model;

class RegistrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========================================
  // 📝 INSCRIPTION AUX ÉVÉNEMENTS
  // ========================================

  /// Inscrire un utilisateur à un événement
  Future<void> registerUserToEvent(String eventId, String userId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'registeredUserIds': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'inscription: $e');
    }
  }

  /// Désinscrire un utilisateur d'un événement
  Future<void> unregisterUserFromEvent(String eventId, String userId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'registeredUserIds': FieldValue.arrayRemove([userId]),
        'confirmedParticipants': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw Exception('Erreur lors de la désinscription: $e');
    }
  }

  // ========================================
  // 🔍 RÉCUPÉRER LES ÉVÉNEMENTS DE L'UTILISATEUR
  // ========================================

  /// Obtenir les événements auxquels l'utilisateur est inscrit (une fois)
  Future<List<Event>> getUserRegisteredEvents(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('registeredUserIds', arrayContains: userId)
          .get();

      return snapshot.docs
          .map((doc) => Event.fromMap(doc.data())) // ✅ Utiliser fromMap
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des événements inscrits: $e');
    }
  }

  /// Obtenir les événements auxquels l'utilisateur est inscrit (stream)
  Stream<List<Event>> getUserRegisteredEventsStream(String userId) {
    return _firestore
        .collection('events')
        .where('registeredUserIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromMap(doc.data())) // ✅ Utiliser fromMap
            .toList());
  }

  /// Obtenir les événements où l'utilisateur a confirmé sa présence (une fois)
  Future<List<Event>> getUserConfirmedEvents(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('confirmedParticipants', arrayContains: userId)
          .get();

      return snapshot.docs
          .map((doc) => Event.fromMap(doc.data())) // ✅ Utiliser fromMap
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des événements confirmés: $e');
    }
  }

  /// Obtenir les événements où l'utilisateur a confirmé sa présence (stream)
  Stream<List<Event>> getUserConfirmedEventsStream(String userId) {
    return _firestore
        .collection('events')
        .where('confirmedParticipants', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromMap(doc.data())) // ✅ Utiliser fromMap
            .toList());
  }

  // ========================================
  // ✅ CONFIRMATION DE PRÉSENCE
  // ========================================

  /// Confirmer la présence de l'utilisateur
  Future<void> confirmUserPresence(String eventId, String userId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'confirmedParticipants': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Erreur lors de la confirmation de présence: $e');
    }
  }

  /// Enlever la confirmation de présence
  Future<void> removePresenceConfirmation(String eventId, String userId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'confirmedParticipants': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la confirmation: $e');
    }
  }

  // ========================================
  // 📊 VÉRIFICATIONS
  // ========================================

  /// Vérifier si l'utilisateur est inscrit à un événement
  Future<bool> isUserRegistered(String eventId, String userId) async {
    try {
      final event = await _firestore.collection('events').doc(eventId).get();
      if (!event.exists) return false;

      final data = event.data() as Map<String, dynamic>;
      final registeredUserIds = List<String>.from(data['registeredUserIds'] ?? []);
      
      return registeredUserIds.contains(userId);
    } catch (e) {
      throw Exception('Erreur lors de la vérification d\'inscription: $e');
    }
  }

  /// Vérifier si l'utilisateur a confirmé sa présence
  Future<bool> isUserConfirmed(String eventId, String userId) async {
    try {
      final event = await _firestore.collection('events').doc(eventId).get();
      if (!event.exists) return false;

      final data = event.data() as Map<String, dynamic>;
      final confirmedParticipants = List<String>.from(data['confirmedParticipants'] ?? []);
      
      return confirmedParticipants.contains(userId);
    } catch (e) {
      throw Exception('Erreur lors de la vérification de confirmation: $e');
    }
  }

  /// Obtenir le nombre d'inscrits pour un événement
  Future<int> getRegisteredCount(String eventId) async {
    try {
      final event = await _firestore.collection('events').doc(eventId).get();
      if (!event.exists) return 0;

      final data = event.data() as Map<String, dynamic>;
      final registeredUserIds = List<String>.from(data['registeredUserIds'] ?? []);
      
      return registeredUserIds.length;
    } catch (e) {
      throw Exception('Erreur lors du comptage des inscrits: $e');
    }
  }

  /// Obtenir le nombre de confirmés pour un événement
  Future<int> getConfirmedCount(String eventId) async {
    try {
      final event = await _firestore.collection('events').doc(eventId).get();
      if (!event.exists) return 0;

      final data = event.data() as Map<String, dynamic>;
      final confirmedParticipants = List<String>.from(data['confirmedParticipants'] ?? []);
      
      return confirmedParticipants.length;
    } catch (e) {
      throw Exception('Erreur lors du comptage des confirmés: $e');
    }
  }

  // ========================================
  // 👥 GESTION DES UTILISATEURS
  // ========================================

  /// Obtenir tous les utilisateurs inscrits à un événement
  Future<List<user_model.User>> getRegisteredUsers(String eventId) async {
    try {
      final event = await _firestore.collection('events').doc(eventId).get();
      if (!event.exists) return [];

      final data = event.data() as Map<String, dynamic>;
      final registeredUserIds = List<String>.from(data['registeredUserIds'] ?? []);

      final users = <user_model.User>[];
      for (final userId in registeredUserIds) {
        try {
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            users.add(user_model.User(
              uid: userId,
              email: userData['email'] ?? '',
              nom: userData['nom'] ?? 'Inconnu',
              prenom: userData['prenom'] ?? '',
              role: _parseUserRole(userData['role']),
              phone: userData['telephone'],
            ));
          }
        } catch (e) {
          print('Erreur lors de la récupération de l\'utilisateur $userId: $e');
        }
      }

      return users;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des utilisateurs inscrits: $e');
    }
  }

  /// Obtenir tous les utilisateurs ayant confirmé pour un événement
  Future<List<user_model.User>> getConfirmedUsers(String eventId) async {
    try {
      final event = await _firestore.collection('events').doc(eventId).get();
      if (!event.exists) return [];

      final data = event.data() as Map<String, dynamic>;
      final confirmedUserIds = List<String>.from(data['confirmedParticipants'] ?? []);

      final users = <user_model.User>[];
      for (final userId in confirmedUserIds) {
        try {
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            users.add(user_model.User(
              uid: userId,
              email: userData['email'] ?? '',
              nom: userData['nom'] ?? 'Inconnu',
              prenom: userData['prenom'] ?? '',
              role: _parseUserRole(userData['role']),
              phone: userData['telephone'],
            ));
          }
        } catch (e) {
          print('Erreur lors de la récupération de l\'utilisateur $userId: $e');
        }
      }

      return users;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des utilisateurs confirmés: $e');
    }
  }

  // ========================================
  // 🔧 HELPERS
  // ========================================

  user_model.UserRole _parseUserRole(dynamic roleValue) {
    if (roleValue == null) return user_model.UserRole.adherent;
    
    final role = roleValue.toString().toLowerCase();
    switch (role) {
      case 'admin':
        return user_model.UserRole.admin;
      case 'invite':
        return user_model.UserRole.invite;
      default:
        return user_model.UserRole.adherent;
    }
  }
}