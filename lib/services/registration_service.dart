// services/registration_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coentrepreneurs/models/event.dart';

class RegistrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _eventsCollection = 'events';

  /// Inscrire un utilisateur à un événement
  Future<void> registerUserToEvent(String eventId, String userId) async {
    try {
      await _firestore.collection(_eventsCollection).doc(eventId).update({
        'registeredUserIds': FieldValue.arrayUnion([userId]),
      });
      print('✅ Utilisateur inscrit à l\'événement: $eventId');
    } catch (e) {
      print('❌ Erreur lors de l\'inscription: $e');
      rethrow;
    }
  }

  /// Désinscrire un utilisateur d'un événement
  Future<void> unregisterUserFromEvent(String eventId, String userId) async {
    try {
      await _firestore.collection(_eventsCollection).doc(eventId).update({
        'registeredUserIds': FieldValue.arrayRemove([userId]),
      });
      print('✅ Utilisateur désinscrit de l\'événement: $eventId');
    } catch (e) {
      print('❌ Erreur lors de la désinscription: $e');
      rethrow;
    }
  }

  /// Vérifier si un utilisateur est inscrit à un événement
  Future<bool> isUserRegistered(String eventId, String userId) async {
    try {
      final doc = await _firestore
          .collection(_eventsCollection)
          .doc(eventId)
          .get();

      if (doc.exists) {
        final event = Event.fromFirestore(doc.data()!, doc.id);
        return event.isUserRegistered(userId);
      }
      return false;
    } catch (e) {
      print('❌ Erreur lors de la vérification: $e');
      return false;
    }
  }

  /// Obtenir les inscriptions d'un utilisateur (événements auxquels il est inscrit)
  Stream<List<Event>> getUserRegistrations(String userId) {
    return _firestore
        .collection(_eventsCollection)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Event.fromFirestore(doc.data(), doc.id))
          .where((event) => event.isUserRegistered(userId))
          .toList();
    });
  }

  /// Obtenir tous les participants d'un événement
  Future<List<String>> getEventParticipants(String eventId) async {
    try {
      final doc = await _firestore
          .collection(_eventsCollection)
          .doc(eventId)
          .get();

      if (doc.exists) {
        final event = Event.fromFirestore(doc.data()!, doc.id);
        return event.registeredUserIds;
      }
      return [];
    } catch (e) {
      print('❌ Erreur lors de la récupération des participants: $e');
      return [];
    }
  }

  /// Vérifier si un événement est complet
  Future<bool> isEventFull(String eventId) async {
    try {
      final doc = await _firestore
          .collection(_eventsCollection)
          .doc(eventId)
          .get();

      if (doc.exists) {
        final event = Event.fromFirestore(doc.data()!, doc.id);
        return event.isFull;
      }
      return false;
    } catch (e) {
      print('❌ Erreur lors de la vérification de capacité: $e');
      return false;
    }
  }
}