// services/invitation_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coentrepreneurs/models/invitation.dart';

class InvitationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========================================
  // 📝 CRÉER UNE INVITATION
  // ========================================

  Future<void> createInvitation({
    required String eventId,
    required String invitedByUserId,
    required String invitedUserPrenom,
    required String invitedUserNom,
    String invitedUserEmail = '',
  }) async {
    try {
      final docRef = _firestore.collection('invitations').doc();
      final invitation = Invitation(
        id: docRef.id,
        eventId: eventId,
        invitedByUserId: invitedByUserId,
        invitedUserEmail: invitedUserEmail,
        invitedUserPrenom: invitedUserPrenom,
        invitedUserNom: invitedUserNom,
        status: InvitationStatus.pending,
        createdAt: DateTime.now(),
      );
      await docRef.set(invitation.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'invitation: $e');
    }
  }

  Future<void> createInvitations({
    required String eventId,
    required String invitedByUserId,
    required List<Map<String, String>> invitations,
  }) async {
    try {
      final batch = _firestore.batch();
      for (final inv in invitations) {
        final docRef = _firestore.collection('invitations').doc();
        final invitation = Invitation(
          id: docRef.id,
          eventId: eventId,
          invitedByUserId: invitedByUserId,
          invitedUserEmail: inv['email'] ?? '',
          invitedUserPrenom: inv['prenom'] ?? '',
          invitedUserNom: inv['nom'] ?? '',
          status: InvitationStatus.pending,
          createdAt: DateTime.now(),
        );
        batch.set(docRef, invitation.toMap());
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de la création des invitations: $e');
    }
  }

  // ========================================
  // 🔍 RÉCUPÉRER LES INVITATIONS
  // ========================================

  Future<List<Invitation>> getReceivedInvitations(String userEmail) async {
    try {
      final snapshot = await _firestore
          .collection('invitations')
          .where('invitedUserEmail', isEqualTo: userEmail)
          .get();
      return snapshot.docs.map((doc) => Invitation.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des invitations: $e');
    }
  }

  Stream<List<Invitation>> getReceivedInvitationsStream(String userEmail) {
    return _firestore
        .collection('invitations')
        .where('invitedUserEmail', isEqualTo: userEmail)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Invitation.fromMap(doc.data())).toList());
  }

  /// Récupérer les invitations pour un événement (stream temps réel)
  Stream<List<Invitation>> getEventInvitationsStream(String eventId) {
    return _firestore
        .collection('invitations')
        .where('eventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Invitation.fromMap(doc.data())).toList());
  }

  Future<List<Invitation>> getSentInvitations(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('invitations')
          .where('invitedByUserId', isEqualTo: userId)
          .get();
      return snapshot.docs.map((doc) => Invitation.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des invitations envoyées: $e');
    }
  }

  Future<List<Invitation>> getEventInvitations(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection('invitations')
          .where('eventId', isEqualTo: eventId)
          .get();
      return snapshot.docs.map((doc) => Invitation.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des invitations de l\'événement: $e');
    }
  }

  Future<Invitation?> getInvitation(String invitationId) async {
    try {
      final doc = await _firestore.collection('invitations').doc(invitationId).get();
      return doc.exists ? Invitation.fromMap(doc.data()!) : null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'invitation: $e');
    }
  }

  // ========================================
  // ✅ ACCEPTER/REFUSER UNE INVITATION
  // ========================================

  Future<void> acceptInvitation(String invitationId) async {
    try {
      await _firestore.collection('invitations').doc(invitationId).update({
        'status': 'accepted',
        'respondedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'acceptation de l\'invitation: $e');
    }
  }

  Future<void> declineInvitation(String invitationId) async {
    try {
      await _firestore.collection('invitations').doc(invitationId).update({
        'status': 'declined',
        'respondedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors du refus de l\'invitation: $e');
    }
  }

  // ========================================
  // 📊 STATISTIQUES
  // ========================================

  Future<int> getPendingInvitationsCount(String userEmail) async {
    try {
      final snapshot = await _firestore
          .collection('invitations')
          .where('invitedUserEmail', isEqualTo: userEmail)
          .where('status', isEqualTo: 'pending')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Erreur lors du comptage des invitations: $e');
    }
  }

  Future<int> getAcceptedInvitationsCount(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection('invitations')
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'accepted')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Erreur lors du comptage des invitations acceptées: $e');
    }
  }

  // ========================================
  // 🗑️ SUPPRIMER
  // ========================================

  Future<void> deleteInvitation(String invitationId) async {
    try {
      await _firestore.collection('invitations').doc(invitationId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'invitation: $e');
    }
  }

  Future<void> deleteEventInvitations(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection('invitations')
          .where('eventId', isEqualTo: eventId)
          .get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de la suppression des invitations de l\'événement: $e');
    }
  }

  // ========================================
  // 🔍 VÉRIFICATIONS
  // ========================================

  Future<bool> hasPendingInvitation(String eventId, String email) async {
    try {
      final snapshot = await _firestore
          .collection('invitations')
          .where('eventId', isEqualTo: eventId)
          .where('invitedUserEmail', isEqualTo: email)
          .where('status', isEqualTo: 'pending')
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Erreur lors de la vérification de l\'invitation: $e');
    }
  }

  Future<bool> hasAcceptedInvitation(String eventId, String email) async {
    try {
      final snapshot = await _firestore
          .collection('invitations')
          .where('eventId', isEqualTo: eventId)
          .where('invitedUserEmail', isEqualTo: email)
          .where('status', isEqualTo: 'accepted')
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Erreur lors de la vérification de l\'acceptation: $e');
    }
  }
}