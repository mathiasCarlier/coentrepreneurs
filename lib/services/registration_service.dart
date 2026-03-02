// services/registration_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coentrepreneurs/models/event.dart';
import 'package:coentrepreneurs/models/user.dart' as user_model;

/// Gère les inscriptions, refus et confirmations de présence aux rencontres.
/// Toutes les mutations s'appliquent sur la table `registrations`.
class RegistrationService {
  SupabaseClient get _supabase => Supabase.instance.client;

  static const _eventSelect = '*, registrations(user_id, status, has_collation)';

  // ========================================
  // INSCRIPTION AUX ÉVÉNEMENTS
  // ========================================

  Future<void> registerUserToEvent(String eventId, String userId) async {
    try {
      await _supabase.from('registrations').insert({
        'event_id': eventId,
        'user_id': userId,
        'status': 'registered',
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'inscription: $e');
    }
  }

  Future<void> unregisterUserFromEvent(String eventId, String userId) async {
    try {
      await _supabase
          .from('registrations')
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Erreur lors de la désinscription: $e');
    }
  }

  Future<void> declineEvent(String eventId, String userId) async {
    try {
      await _supabase.from('registrations').upsert({
        'event_id': eventId,
        'user_id': userId,
        'status': 'declined',
        'responded_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Erreur lors du refus: $e');
    }
  }

  Future<void> cancelDecline(String eventId, String userId) async {
    try {
      await _supabase
          .from('registrations')
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .eq('status', 'declined');
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation du refus: $e');
    }
  }

  // ========================================
  // COLLATION
  // ========================================

  Future<void> saveCollationChoice(String eventId, String userId, bool participates) async {
    try {
      await _supabase
          .from('registrations')
          .update({'has_collation': participates})
          .eq('event_id', eventId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Erreur lors de l\'enregistrement du choix de collation: $e');
    }
  }

  Future<void> removeCollationChoice(String eventId, String userId) async {
    try {
      await _supabase
          .from('registrations')
          .update({'has_collation': false})
          .eq('event_id', eventId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du choix de collation: $e');
    }
  }

  // ========================================
  // RÉCUPÉRER LES ÉVÉNEMENTS DE L'UTILISATEUR
  // ========================================

  Future<List<Event>> getUserRegisteredEvents(String userId) async {
    try {
      final regs = await _supabase
          .from('registrations')
          .select('event_id')
          .eq('user_id', userId)
          .neq('status', 'declined');
      if ((regs as List).isEmpty) return [];
      final eventIds = regs.map((r) => r['event_id'] as String).toList();
      final data = await _supabase
          .from('events')
          .select(_eventSelect)
          .inFilter('id', eventIds);
      return (data as List).map((e) => Event.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des événements inscrits: $e');
    }
  }

  Stream<List<Event>> getUserRegisteredEventsStream(String userId) {
    return _supabase
        .from('registrations')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .asyncMap((regs) async {
          final active = regs.where((r) => r['status'] != 'declined').toList();
          if (active.isEmpty) return <Event>[];
          final eventIds = active.map((r) => r['event_id'] as String).toList();
          final data = await _supabase
              .from('events')
              .select(_eventSelect)
              .inFilter('id', eventIds);
          return (data as List).map((e) => Event.fromMap(e)).toList();
        });
  }

  Future<List<Event>> getUserConfirmedEvents(String userId) async {
    try {
      final regs = await _supabase
          .from('registrations')
          .select('event_id')
          .eq('user_id', userId)
          .eq('status', 'confirmed');
      if ((regs as List).isEmpty) return [];
      final eventIds = regs.map((r) => r['event_id'] as String).toList();
      final data = await _supabase
          .from('events')
          .select(_eventSelect)
          .inFilter('id', eventIds);
      return (data as List).map((e) => Event.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des événements confirmés: $e');
    }
  }

  Stream<List<Event>> getUserConfirmedEventsStream(String userId) {
    return _supabase
        .from('registrations')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .asyncMap((regs) async {
          final confirmed = regs.where((r) => r['status'] == 'confirmed').toList();
          if (confirmed.isEmpty) return <Event>[];
          final eventIds = confirmed.map((r) => r['event_id'] as String).toList();
          final data = await _supabase
              .from('events')
              .select(_eventSelect)
              .inFilter('id', eventIds);
          return (data as List).map((e) => Event.fromMap(e)).toList();
        });
  }

  // ========================================
  // CONFIRMATION DE PRÉSENCE
  // ========================================

  Future<void> confirmUserPresence(String eventId, String userId) async {
    try {
      await _supabase
          .from('registrations')
          .update({'status': 'confirmed', 'responded_at': DateTime.now().toIso8601String()})
          .eq('event_id', eventId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Erreur lors de la confirmation de présence: $e');
    }
  }

  Future<void> removePresenceConfirmation(String eventId, String userId) async {
    try {
      await _supabase
          .from('registrations')
          .update({'status': 'registered', 'responded_at': null})
          .eq('event_id', eventId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la confirmation: $e');
    }
  }

  // ========================================
  // VÉRIFICATIONS
  // ========================================

  Future<bool> isUserRegistered(String eventId, String userId) async {
    try {
      final data = await _supabase
          .from('registrations')
          .select('status')
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();
      if (data == null) return false;
      return data['status'] == 'registered' || data['status'] == 'confirmed';
    } catch (e) {
      throw Exception('Erreur lors de la vérification d\'inscription: $e');
    }
  }

  Future<bool> isUserConfirmed(String eventId, String userId) async {
    try {
      final data = await _supabase
          .from('registrations')
          .select('status')
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();
      return data?['status'] == 'confirmed';
    } catch (e) {
      throw Exception('Erreur lors de la vérification de confirmation: $e');
    }
  }

  Future<int> getRegisteredCount(String eventId) async {
    try {
      final data = await _supabase
          .from('registrations')
          .select('id')
          .eq('event_id', eventId)
          .neq('status', 'declined');
      return (data as List).length;
    } catch (e) {
      throw Exception('Erreur lors du comptage des inscrits: $e');
    }
  }

  Future<int> getConfirmedCount(String eventId) async {
    try {
      final data = await _supabase
          .from('registrations')
          .select('id')
          .eq('event_id', eventId)
          .eq('status', 'confirmed');
      return (data as List).length;
    } catch (e) {
      throw Exception('Erreur lors du comptage des confirmés: $e');
    }
  }

  // ========================================
  // GESTION DES UTILISATEURS
  // ========================================

  Future<List<user_model.User>> getRegisteredUsers(String eventId) async {
    try {
      final data = await _supabase
          .from('registrations')
          .select('user_id, users(id, email, nom, prenom, role, phone)')
          .eq('event_id', eventId)
          .neq('status', 'declined');
      final users = <user_model.User>[];
      for (final row in (data as List)) {
        final u = row['users'] as Map<String, dynamic>?;
        if (u != null) {
          users.add(_userFromMap(u));
        }
      }
      return users;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des utilisateurs inscrits: $e');
    }
  }

  Future<List<user_model.User>> getConfirmedUsers(String eventId) async {
    try {
      final data = await _supabase
          .from('registrations')
          .select('user_id, users(id, email, nom, prenom, role, phone)')
          .eq('event_id', eventId)
          .eq('status', 'confirmed');
      final users = <user_model.User>[];
      for (final row in (data as List)) {
        final u = row['users'] as Map<String, dynamic>?;
        if (u != null) {
          users.add(_userFromMap(u));
        }
      }
      return users;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des utilisateurs confirmés: $e');
    }
  }

  // ========================================
  // HELPERS
  // ========================================

  user_model.User _userFromMap(Map<String, dynamic> u) {
    return user_model.User(
      uid: u['id'] ?? '',
      email: u['email'] ?? '',
      nom: u['nom'] ?? 'Inconnu',
      prenom: u['prenom'] ?? '',
      role: _parseUserRole(u['role']),
      phone: u['phone'] ?? '',
    );
  }

  user_model.UserRole _parseUserRole(dynamic roleValue) {
    if (roleValue == null) return user_model.UserRole.adherent;
    switch (roleValue.toString().toLowerCase()) {
      case 'admin':
        return user_model.UserRole.admin;
      case 'invite':
        return user_model.UserRole.invite;
      default:
        return user_model.UserRole.adherent;
    }
  }
}
