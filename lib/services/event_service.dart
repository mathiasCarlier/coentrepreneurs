// services/event_service.dart - VERSION FINALE COMPLÈTE

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:coentrepreneurs/models/event.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========================================
  // 📝 OPÉRATIONS CRUD
  // ========================================

  /// Créer un nouvel événement
  Future<void> createEvent(Event event) async {
    try {
      final docRef = _firestore.collection('events').doc();
      final newEvent = event.copyWith(id: docRef.id);
      final map = newEvent.toMap();
      // Ajouter createdAt côté serveur pour pouvoir détecter les nouveautés
      map['createdAt'] = FieldValue.serverTimestamp();
      await docRef.set(map);
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'événement: $e');
    }
  }

  /// Mettre à jour un événement existant
  Future<void> updateEvent(String eventId, Event event) async {
    try {
      await _firestore.collection('events').doc(eventId).set(
        event.copyWith(id: eventId).toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'événement: $e');
    }
  }

  /// Supprimer un événement
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'événement: $e');
    }
  }

  // ========================================
  // 🔍 LECTURES
  // ========================================

  /// Récupérer tous les événements (stream)
  Stream<List<Event>> getAllEventsStream() {
    return _firestore
        .collection('events')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return Event.fromMap(doc.data());
                } catch (e) {
                  debugPrint('Erreur parsing événement ${doc.id}: $e');
                  rethrow;
                }
              })
              .toList();
        });
  }

  /// Récupérer tous les événements (une seule fois)
  Future<List<Event>> getAllEvents() async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .orderBy('date', descending: false)
          .get();
      
      return snapshot.docs
          .map((doc) => Event.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des événements: $e');
    }
  }

  /// Mettre à jour le compte-rendu (Markdown) d'un événement terminé
  Future<void> updateEventSummary(String eventId, String summary) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'summary': summary,
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du compte-rendu: $e');
    }
  }

  /// Récupérer un événement spécifique
  Future<Event?> getEvent(String eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();
      return doc.exists ? Event.fromMap(doc.data()!) : null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'événement: $e');
    }
  }

  /// Récupérer les événements auxquels un utilisateur est inscrit (stream)
  Stream<List<Event>> getUserEventsStream(String userId) {
    return _firestore
        .collection('events')
        .where('registeredUserIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Event.fromMap(doc.data()))
              .toList();
        });
  }

  /// Récupérer les événements auxquels un utilisateur est inscrit (une seule fois)
  Future<List<Event>> getUserEvents(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('registeredUserIds', arrayContains: userId)
          .get();
      
      return snapshot.docs
          .map((doc) => Event.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des événements utilisateur: $e');
    }
  }

  /// Récupérer les événements où l'utilisateur a confirmé sa présence
  Future<List<Event>> getUserConfirmedEvents(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('confirmedParticipants', arrayContains: userId)
          .get();
      
      return snapshot.docs
          .map((doc) => Event.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des événements confirmés: $e');
    }
  }

  /// Compter les événements
  Future<int> countEvents() async {
    try {
      final snapshot = await _firestore.collection('events').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Erreur lors du comptage des événements: $e');
    }
  }

  // ========================================
  // 👥 GESTION DES INSCRIPTIONS
  // ========================================

  /// Inscrire un utilisateur à un événement
  Future<void> registerUserToEvent(String eventId, String userId) async {
    try {
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Événement non trouvé');
      }

      final event = Event.fromMap(eventDoc.data()!);
      
      // Vérifier que l'utilisateur n'est pas déjà inscrit
      if (event.registeredUserIds.contains(userId)) {
        throw Exception('Utilisateur déjà inscrit');
      }

      // Vérifier la capacité
      if (event.isFull) {
        throw Exception('Événement complet');
      }

      final updatedUserIds = event.registeredUserIds.toList();
      updatedUserIds.add(userId);

      await _firestore.collection('events').doc(eventId).update({
        'registeredUserIds': updatedUserIds,
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'inscription: $e');
    }
  }

  /// Désinscrire un utilisateur d'un événement
  Future<void> unregisterUserFromEvent(String eventId, String userId) async {
    try {
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Événement non trouvé');
      }

      final event = Event.fromMap(eventDoc.data()!);
      
      final updatedUserIds = event.registeredUserIds
          .where((id) => id != userId)
          .toList();
      
      // Enlever aussi de la liste des confirmés
      final updatedConfirmed = event.confirmedParticipants
          .where((id) => id != userId)
          .toList();

      await _firestore.collection('events').doc(eventId).update({
        'registeredUserIds': updatedUserIds,
        'confirmedParticipants': updatedConfirmed,
      });
    } catch (e) {
      throw Exception('Erreur lors de la désinscription: $e');
    }
  }

  // ========================================
  // ✅ GESTION DE LA CONFIRMATION DE PRÉSENCE
  // ========================================

  /// Changer l'état de l'événement (pending -> started -> finished)
  Future<void> updateEventStatus(String eventId, EventStatus newStatus) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'status': newStatus.toString().split('.').last,
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut: $e');
    }
  }

  /// Confirmer la présence d'un utilisateur à un événement
  Future<void> confirmUserPresence(String eventId, String userId) async {
    try {
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Événement non trouvé');
      }

      final event = Event.fromMap(eventDoc.data()!);

      // Vérifier que l'utilisateur est inscrit
      if (!event.registeredUserIds.contains(userId)) {
        throw Exception('Utilisateur non inscrit à cet événement');
      }

      // Vérifier que l'événement a commencé
      if (event.status != EventStatus.started) {
        throw Exception('L\'événement n\'a pas commencé');
      }

      // Vérifier qu'il n'est pas déjà confirmé
      if (event.confirmedParticipants.contains(userId)) {
        throw Exception('Utilisateur déjà confirmé');
      }

      final updatedConfirmed = event.confirmedParticipants.toList();
      updatedConfirmed.add(userId);

      await _firestore.collection('events').doc(eventId).update({
        'confirmedParticipants': updatedConfirmed,
      });
    } catch (e) {
      throw Exception('Erreur lors de la confirmation: $e');
    }
  }

  /// Enlever une confirmation de présence
  Future<void> removePresenceConfirmation(String eventId, String userId) async {
    try {
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Événement non trouvé');
      }

      final event = Event.fromMap(eventDoc.data()!);
      final updatedConfirmed = event.confirmedParticipants
          .where((id) => id != userId)
          .toList();

      await _firestore.collection('events').doc(eventId).update({
        'confirmedParticipants': updatedConfirmed,
      });
    } catch (e) {
      throw Exception('Erreur lors de la suppression de confirmation: $e');
    }
  }

  /// Obtenir le nombre de confirmés pour un événement
  Future<int> getConfirmedCount(String eventId) async {
    try {
      final event = await getEvent(eventId);
      return event?.confirmedParticipants.length ?? 0;
    } catch (e) {
      throw Exception('Erreur lors du comptage des confirmés: $e');
    }
  }

  // ========================================
  // 📊 STATISTIQUES
  // ========================================

  /// Obtenir les statistiques d'un événement
  Future<Map<String, dynamic>> getEventStats(String eventId) async {
    try {
      final event = await getEvent(eventId);
      if (event == null) {
        throw Exception('Événement non trouvé');
      }

      return {
        'id': event.id,
        'theme': event.theme,
        'totalInscrits': event.currentParticipants,
        'maxParticipants': event.maxParticipants,
        'tauxRemplissage': event.registrationPercentage,
        'totalConfirmes': event.confirmedParticipants.length,
        'tauxConfirmation': event.currentParticipants > 0
            ? event.confirmedParticipants.length / event.currentParticipants
            : 0,
        'status': event.status.toString().split('.').last,
      };
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }

  /// Obtenir tous les utilisateurs inscrits à un événement
  Future<List<String>> getRegisteredUsers(String eventId) async {
    try {
      final event = await getEvent(eventId);
      return event?.registeredUserIds ?? [];
    } catch (e) {
      throw Exception('Erreur lors de la récupération des utilisateurs inscrits: $e');
    }
  }

  /// Obtenir tous les utilisateurs ayant confirmé pour un événement
  Future<List<String>> getConfirmedUsers(String eventId) async {
    try {
      final event = await getEvent(eventId);
      return event?.confirmedParticipants ?? [];
    } catch (e) {
      throw Exception('Erreur lors de la récupération des utilisateurs confirmés: $e');
    }
  }

  // ========================================
  // 🔍 RECHERCHE
  // ========================================

  /// Chercher des événements par thème
  Future<List<Event>> searchEventsByTheme(String query) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('theme', isGreaterThanOrEqualTo: query)
          .where('theme', isLessThan: '${query}z')
          .get();
      
      return snapshot.docs
          .map((doc) => Event.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  /// Obtenir les événements à venir
  Future<List<Event>> getUpcomingEvents() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('events')
          .where('date', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('date')
          .get();
      
      return snapshot.docs
          .map((doc) => Event.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des événements à venir: $e');
    }
  }

  /// Obtenir les événements passés
  Future<List<Event>> getPastEvents() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('events')
          .where('date', isLessThan: Timestamp.fromDate(now))
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Event.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des événements passés: $e');
    }
  }

  // ========================================
  // 🎯 INITIALISATION DES ÉVÉNEMENTS PAR DÉFAUT
  // ========================================

  /// Initialiser les événements par défaut
  /// À appeler une fois au démarrage de l'application
  Future<void> initializeDefaultEvents() async {
    try {
      final snapshot = await _firestore.collection('events').count().get();
      
      // Si des événements existent déjà, ne pas initialiser
      if ((snapshot.count ?? 0) > 0) {
        debugPrint('✅ Des événements existent déjà. Initialisation ignorée.');
        return;
      }

      debugPrint('📝 Initialisation des événements par défaut...');

      // Créer des événements d'exemple
      final now = DateTime.now();
      final events = [
        Event(
          id: '', // Sera généré par Firestore
          date: now.add(const Duration(days: 7)),
          theme: 'Introduction à Flutter',
          intervenant: 'Jean Dupont',
          entreprise: 'Tech Solutions',
          lieu: 'Paris, France',
          maxParticipants: 30,
          registeredUserIds: [],
          confirmedParticipants: [],
          status: EventStatus.pending,
        ),
        Event(
          id: '',
          date: now.add(const Duration(days: 14)),
          theme: 'Développement Mobile Avancé',
          intervenant: 'Marie Martin',
          entreprise: 'DevApp Inc',
          lieu: 'Lyon, France',
          maxParticipants: 25,
          registeredUserIds: [],
          confirmedParticipants: [],
          status: EventStatus.pending,
        ),
        Event(
          id: '',
          date: now.add(const Duration(days: 21)),
          theme: 'Cloud et Backend avec Firebase',
          intervenant: 'Pierre Bernard',
          entreprise: 'Cloud Experts',
          lieu: 'Bordeaux, France',
          maxParticipants: 20,
          registeredUserIds: [],
          confirmedParticipants: [],
          status: EventStatus.pending,
        ),
      ];

      // Créer chaque événement
      for (final event in events) {
        await createEvent(event);
      }

      debugPrint('✅ ${events.length} événements par défaut créés avec succès!');
    } catch (e) {
      debugPrint('⚠️ Erreur lors de l\'initialisation des événements: $e');
      // Ne pas lever d'exception, juste un warning
    }
  }

  /// Nettoyer tous les événements (à utiliser avec précaution!)
  Future<void> clearAllEvents() async {
    try {
      final snapshot = await _firestore.collection('events').get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      debugPrint('✅ Tous les événements ont été supprimés.');
    } catch (e) {
      throw Exception('Erreur lors de la suppression des événements: $e');
    }
  }
}