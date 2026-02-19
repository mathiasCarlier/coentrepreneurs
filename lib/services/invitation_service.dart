// services/invitation_service.dart - CORRIGÉ (sans Cloud Function, avec email)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coentrepreneurs/models/invitation.dart';

class InvitationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========================================
  // 📝 CRÉER UNE INVITATION SIMPLE
  // ========================================

  Future<void> createInvitation({
    required String eventId,
    required String invitedByUserId,
    required String invitedUserEmail,
    required String invitedUserPrenom,
    required String invitedUserNom,
  }) async {
    try {
      final docRef = _firestore.collection('invitations').doc();
      final invitation = Invitation(
        id: docRef.id,
        eventId: eventId,
        invitedByUserId: invitedByUserId,
        invitedUserEmail: invitedUserEmail, // ✅ EMAIL INCLUS
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

  // ========================================
  // ✨ CRÉER UTILISATEURS + INVITATIONS (CORRIGÉ)
  // ========================================

  /// Crée les utilisateurs invités et les invitations
  /// ✅ AVEC EMAIL - Juste sauvegardé, pas d'envoi de mail
  Future<void> createInvitationsWithUsers({
    required String eventId,
    required String invitedByUserId,
    required List<Map<String, String>> invitations,
  }) async {
    try {
      print('🚀 Création de ${invitations.length} invitation(s) avec utilisateurs...');
      
      final batch = _firestore.batch();

      for (final inv in invitations) {
        final email = inv['email']?.toLowerCase().trim() ?? '';
        final prenom = inv['prenom']?.trim() ?? '';
        final nom = inv['nom']?.trim() ?? '';

        // ✅ EMAIL EST REQUIS
        if (email.isEmpty || prenom.isEmpty || nom.isEmpty) {
          throw Exception('Données invalides: email, prenom et nom sont obligatoires');
        }

        print('\n📝 Traitement: $prenom $nom ($email)');

        // 1️⃣ Vérifier si l'utilisateur existe déjà
        print('   1️⃣ Vérification utilisateur...');
        final existingUsers = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .get();

        String userId;

        if (existingUsers.docs.isNotEmpty) {
          // Utilisateur existe déjà
          userId = existingUsers.docs.first.id;
          print('   ✅ Utilisateur existe: $userId');
        } else {
          // Créer un nouvel utilisateur avec rôle "invite"
          print('   📝 Création nouvel utilisateur...');
          final newUserRef = _firestore.collection('users').doc();
          userId = newUserRef.id;

          final userData = {
            'email': email, // ✅ EMAIL SAUVEGARDÉ
            'prenom': prenom.trim(),
            'nom': nom.trim(),
            'role': 'invite', // ✅ Rôle invite
            'telephone': '',
            'createdAt': FieldValue.serverTimestamp(),
            'isActive': true,
          };

          batch.set(newUserRef, userData);
          print('   ✅ Utilisateur créé: $userId avec email: $email');
        }

        // 2️⃣ Créer l'invitation liée à cet utilisateur
        print('   2️⃣ Création invitation...');
        final invitationRef = _firestore.collection('invitations').doc();

        final invitation = Invitation(
          id: invitationRef.id,
          eventId: eventId,
          invitedByUserId: invitedByUserId,
          invitedUserEmail: email, // ✅ EMAIL DANS INVITATION
          invitedUserPrenom: prenom,
          invitedUserNom: nom,
          status: InvitationStatus.pending,
          createdAt: DateTime.now(),
        );

        batch.set(invitationRef, invitation.toMap());
        print('   ✅ Invitation créée: ${invitationRef.id}');
      }

      print('\n⏳ Validation du batch...');
      await batch.commit();
      print('✅ Batch commit réussi - ${invitations.length} invitation(s) créée(s)\n');
    } catch (e) {
      print('❌ Erreur: $e');
      throw Exception('Erreur lors de la création des invitations: $e');
    }
  }

  // ========================================
  // 🔄 CRÉER INVITATIONS (ancien - compatibilité)
  // ========================================

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
          invitedUserEmail: inv['email'] ?? '', // ✅ EMAIL INCLUS
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