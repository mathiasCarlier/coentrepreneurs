// services/invitation_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coentrepreneurs/models/invitation.dart';

class InvitationService {
  SupabaseClient get _supabase => Supabase.instance.client;

  // ========================================
  // CRÉER UNE INVITATION SIMPLE
  // ========================================

  Future<void> createInvitation({
    required String eventId,
    required String invitedByUserId,
    required String invitedUserEmail,
    required String invitedUserPrenom,
    required String invitedUserNom,
  }) async {
    try {
      final invitation = Invitation(
        id: '',
        eventId: eventId,
        invitedByUserId: invitedByUserId,
        invitedUserEmail: invitedUserEmail,
        invitedUserPrenom: invitedUserPrenom,
        invitedUserNom: invitedUserNom,
        status: InvitationStatus.pending,
        createdAt: DateTime.now(),
      );
      await _supabase.from('invitations').insert(invitation.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'invitation: $e');
    }
  }

  // ========================================
  // CRÉER INVITATIONS AVEC INSCRIPTION À L'ÉVÉNEMENT
  // ========================================

  /// Crée les invitations et inscrit automatiquement les invités à l'événement
  /// si leur compte existe déjà dans la table users.
  Future<void> createInvitationsWithUsers({
    required String eventId,
    required String invitedByUserId,
    required List<Map<String, String>> invitations,
  }) async {
    try {
      debugPrint('🚀 Création de ${invitations.length} invitation(s)...');

      for (final inv in invitations) {
        final email = inv['email']?.toLowerCase().trim() ?? '';
        final prenom = inv['prenom']?.trim() ?? '';
        final nom = inv['nom']?.trim() ?? '';

        if (email.isEmpty || prenom.isEmpty || nom.isEmpty) {
          throw Exception('Données invalides: email, prenom et nom sont obligatoires');
        }

        debugPrint('📝 Traitement: $prenom $nom ($email)');

        // Créer l'invitation
        await _supabase.from('invitations').insert({
          'event_id': eventId,
          'invited_by_user_id': invitedByUserId,
          'invited_user_email': email,
          'invited_user_prenom': prenom,
          'invited_user_nom': nom,
          'status': 'pending',
        });

        // Si l'utilisateur a déjà un compte, l'inscrire directement à l'événement
        final existingUser = await _supabase
            .from('users')
            .select('id')
            .eq('email', email)
            .maybeSingle();

        if (existingUser != null) {
          final userId = existingUser['id'] as String;
          debugPrint('   ✅ Utilisateur existant trouvé: $userId');
          // Upsert pour éviter les doublons
          await _supabase.from('registrations').upsert({
            'event_id': eventId,
            'user_id': userId,
            'status': 'registered',
          });
        }
      }

      debugPrint('✅ ${invitations.length} invitation(s) créée(s) avec succès!');
    } catch (e) {
      debugPrint('❌ Erreur: $e');
      throw Exception('Erreur lors de la création des invitations: $e');
    }
  }

  // ========================================
  // RÉCUPÉRER LES INVITATIONS
  // ========================================

  Future<List<Invitation>> getReceivedInvitations(String userEmail) async {
    try {
      final data = await _supabase
          .from('invitations')
          .select()
          .eq('invited_user_email', userEmail);
      return (data as List).map((e) => Invitation.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des invitations: $e');
    }
  }

  Stream<List<Invitation>> getReceivedInvitationsStream(String userEmail) {
    return _supabase
        .from('invitations')
        .stream(primaryKey: ['id'])
        .eq('invited_user_email', userEmail)
        .map((data) => data
            .map((e) => Invitation.fromMap(e))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Stream<List<Invitation>> getEventInvitationsStream(String eventId) {
    return _supabase
        .from('invitations')
        .stream(primaryKey: ['id'])
        .eq('event_id', eventId)
        .map((data) => data
            .map((e) => Invitation.fromMap(e))
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
  }

  Future<List<Invitation>> getSentInvitations(String userId) async {
    try {
      final data = await _supabase
          .from('invitations')
          .select()
          .eq('invited_by_user_id', userId);
      return (data as List).map((e) => Invitation.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des invitations envoyées: $e');
    }
  }

  Future<List<Invitation>> getEventInvitations(String eventId) async {
    try {
      final data = await _supabase
          .from('invitations')
          .select()
          .eq('event_id', eventId);
      return (data as List).map((e) => Invitation.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des invitations de l\'événement: $e');
    }
  }

  Future<Invitation?> getInvitation(String invitationId) async {
    try {
      final data = await _supabase
          .from('invitations')
          .select()
          .eq('id', invitationId)
          .maybeSingle();
      return data != null ? Invitation.fromMap(data) : null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'invitation: $e');
    }
  }

  // ========================================
  // ACCEPTER / REFUSER UNE INVITATION
  // ========================================

  Future<void> acceptInvitation(String invitationId) async {
    try {
      await _supabase.from('invitations').update({
        'status': 'accepted',
        'responded_at': DateTime.now().toIso8601String(),
      }).eq('id', invitationId);
    } catch (e) {
      throw Exception('Erreur lors de l\'acceptation de l\'invitation: $e');
    }
  }

  Future<void> declineInvitation(String invitationId) async {
    try {
      await _supabase.from('invitations').update({
        'status': 'declined',
        'responded_at': DateTime.now().toIso8601String(),
      }).eq('id', invitationId);
    } catch (e) {
      throw Exception('Erreur lors du refus de l\'invitation: $e');
    }
  }

  // ========================================
  // STATISTIQUES
  // ========================================

  Future<int> getPendingInvitationsCount(String userEmail) async {
    try {
      final data = await _supabase
          .from('invitations')
          .select('id')
          .eq('invited_user_email', userEmail)
          .eq('status', 'pending');
      return (data as List).length;
    } catch (e) {
      throw Exception('Erreur lors du comptage des invitations: $e');
    }
  }

  Future<int> getAcceptedInvitationsCount(String eventId) async {
    try {
      final data = await _supabase
          .from('invitations')
          .select('id')
          .eq('event_id', eventId)
          .eq('status', 'accepted');
      return (data as List).length;
    } catch (e) {
      throw Exception('Erreur lors du comptage des invitations acceptées: $e');
    }
  }

  // ========================================
  // SUPPRIMER
  // ========================================

  Future<void> deleteInvitation(String invitationId) async {
    try {
      await _supabase.from('invitations').delete().eq('id', invitationId);
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'invitation: $e');
    }
  }

  Future<void> deleteEventInvitations(String eventId) async {
    try {
      await _supabase.from('invitations').delete().eq('event_id', eventId);
    } catch (e) {
      throw Exception('Erreur lors de la suppression des invitations de l\'événement: $e');
    }
  }

  // ========================================
  // VÉRIFICATIONS
  // ========================================

  Future<bool> hasPendingInvitation(String eventId, String email) async {
    try {
      final data = await _supabase
          .from('invitations')
          .select('id')
          .eq('event_id', eventId)
          .eq('invited_user_email', email)
          .eq('status', 'pending');
      return (data as List).isNotEmpty;
    } catch (e) {
      throw Exception('Erreur lors de la vérification de l\'invitation: $e');
    }
  }

  Future<bool> hasAcceptedInvitation(String eventId, String email) async {
    try {
      final data = await _supabase
          .from('invitations')
          .select('id')
          .eq('event_id', eventId)
          .eq('invited_user_email', email)
          .eq('status', 'accepted');
      return (data as List).isNotEmpty;
    } catch (e) {
      throw Exception('Erreur lors de la vérification de l\'acceptation: $e');
    }
  }
}
