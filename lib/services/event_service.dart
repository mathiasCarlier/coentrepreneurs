// services/event_service.dart - VERSION MISE À JOUR AVEC ACCEPTATIONS
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coentrepreneurs/models/event.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _eventsCollection = 'events';

  /// Récupérer tous les événements (avec ordre par date)
  Stream<List<Event>> getAllEventsStream() {
    return _firestore
        .collection(_eventsCollection)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Event.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  /// Récupérer un événement par ID
  Future<Event?> getEventById(String eventId) async {
    try {
      final doc = await _firestore
          .collection(_eventsCollection)
          .doc(eventId)
          .get();

      if (doc.exists) {
        return Event.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('❌ Error getting event: $e');
      return null;
    }
  }

  /// Créer un nouvel événement (admin uniquement)
  Future<String> createEvent(Event event) async {
    try {
      final docRef = await _firestore.collection(_eventsCollection).add({
        'date': event.date,
        'theme': event.theme,
        'intervenant': event.intervenant,
        'entreprise': event.entreprise,
        'lieu': event.lieu,
        'registeredUserIds': event.registeredUserIds,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      print('❌ Error creating event: $e');
      rethrow;
    }
  }

  /// Mettre à jour un événement (admin uniquement)
  Future<void> updateEvent(String eventId, Event event) async {
    try {
      await _firestore.collection(_eventsCollection).doc(eventId).update({
        'date': event.date,
        'theme': event.theme,
        'intervenant': event.intervenant,
        'entreprise': event.entreprise,
        'lieu': event.lieu,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error updating event: $e');
      rethrow;
    }
  }

  /// Supprimer un événement (admin uniquement)
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection(_eventsCollection).doc(eventId).delete();
    } catch (e) {
      print('❌ Error deleting event: $e');
      rethrow;
    }
  }

  // ============================================
  // NOUVEAU: Méthodes pour les acceptations
  // ============================================

  /// Accepter la participation d'un utilisateur
  /// Cette action rend la désinscription impossible
  Future<void> acceptParticipation(String eventId, String userId) async {
    try {
      final eventRef = _firestore.collection(_eventsCollection).doc(eventId);
      
      // Vérifier que l'utilisateur est inscrit
      final eventDoc = await eventRef.get();
      if (!eventDoc.exists) {
        throw Exception('Événement non trouvé');
      }

      final registeredUserIds = List<String>.from(
        eventDoc['registeredUserIds'] ?? []
      );

      if (!registeredUserIds.contains(userId)) {
        throw Exception('Vous n\'êtes pas inscrit à cet événement');
      }

      // Ajouter à acceptedParticipants
      await eventRef.update({
        'acceptedParticipants': FieldValue.arrayUnion([userId]),
      });

      print('✅ User $userId accepted participation for event $eventId');
    } catch (e) {
      print('❌ Error accepting participation: $e');
      rethrow;
    }
  }

  /// Vérifier si un utilisateur a accepté sa participation
  Future<bool> isUserAccepted(String eventId, String userId) async {
    try {
      final eventDoc = await _firestore
          .collection(_eventsCollection)
          .doc(eventId)
          .get();

      if (!eventDoc.exists) return false;

      final acceptedParticipants = List<String>.from(
        eventDoc['acceptedParticipants'] ?? []
      );

      return acceptedParticipants.contains(userId);
    } catch (e) {
      print('❌ Error checking acceptance: $e');
      return false;
    }
  }

  /// Révoquer l'acceptation d'un utilisateur (admin uniquement)
  /// Permet de le laisser se désinscrire
  Future<void> revokeAcceptance(String eventId, String userId) async {
    try {
      final eventRef = _firestore.collection(_eventsCollection).doc(eventId);
      
      await eventRef.update({
        'acceptedParticipants': FieldValue.arrayRemove([userId]),
      });

      print('✅ Acceptance revoked for user $userId from event $eventId');
    } catch (e) {
      print('❌ Error revoking acceptance: $e');
      rethrow;
    }
  }

  /// Initialiser les événements par défaut (exécuter une seule fois)
  Future<void> initializeDefaultEvents() async {
    try {
      // Vérifier si des événements existent déjà
      final snapshot = await _firestore.collection(_eventsCollection).limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        print('✅ Events already exist, skipping initialization');
        return;
      }

      // Créer les événements par défaut
      final defaultEvents = [
        {
          'date': DateTime(2026, 3, 5),
          'theme': 'La dématérialisation des factures achats/ventes. Comment faire ?',
          'intervenant': 'Guillaume Massonnet',
          'entreprise': 'Fiducial loudun',
          'lieu': '2 lieux sont en compétition. Précision dans 3 jours',
          'registeredUserIds': [],
          'acceptedParticipants': [],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'date': DateTime(2026, 4, 2),
          'theme': 'Pourquoi la cotisation de l\'assurance augmente ?',
          'intervenant': 'Willy DUBARD',
          'entreprise': 'Allianz',
          'lieu': 'place de la boeuffeterie 86200 LOUDUN',
          'registeredUserIds': [],
          'acceptedParticipants': [],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'date': DateTime(2026, 5, 7),
          'theme': 'On fête les 10 ans',
          'intervenant': 'Les membres des coentrepreneurs',
          'entreprise': 'non défini',
          'lieu': 'en cours de définition',
          'registeredUserIds': [],
          'acceptedParticipants': [],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      // Ajouter chaque événement
      for (var eventData in defaultEvents) {
        await _firestore.collection(_eventsCollection).add(eventData);
      }

    } catch (e) {
      print('❌ Error initializing default events: $e');
      rethrow;
    }
  }

  /// Confirmer la participation d'un utilisateur à un événement
  Future<void> confirmParticipation(String eventId, String userId) async {
    try {
      final eventRef = _firestore.collection('events').doc(eventId);
      final eventDoc = await eventRef.get();

      if (!eventDoc.exists) {
        throw Exception('Événement non trouvé');
      }

      // Vérifier que l'utilisateur est inscrit
      final registeredUserIds = List<String>.from(
        eventDoc['registeredUserIds'] ?? []
      );
      if (!registeredUserIds.contains(userId)) {
        throw Exception('Vous n\'êtes pas inscrit à cet événement');
      }

      // Ajouter à confirmedParticipants
      await eventRef.update({
        'confirmedParticipants': FieldValue.arrayUnion([userId]),
      });

      print('✅ Participation confirmée pour $userId');
    } catch (e) {
      print('❌ Erreur lors de la confirmation: $e');
      rethrow;
    }
  }
}
