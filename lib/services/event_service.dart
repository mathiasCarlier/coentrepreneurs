// services/event_service.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coentrepreneurs/models/event.dart';

class EventService {
  SupabaseClient get _supabase => Supabase.instance.client;

  // Requête de sélection avec le join registrations
  static const _select = '*, registrations(user_id, status, has_collation)';

  // ========================================
  // OPÉRATIONS CRUD
  // ========================================

  Future<void> createEvent(Event event) async {
    try {
      final map = event.toMap();
      map.remove('id'); // Laisse Supabase générer l'UUID
      await _supabase.from('events').insert(map);
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'événement: $e');
    }
  }

  Future<void> updateEvent(String eventId, Event event) async {
    try {
      final map = event.toMap();
      map.remove('id');
      await _supabase.from('events').update(map).eq('id', eventId);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'événement: $e');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _supabase.from('events').delete().eq('id', eventId);
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'événement: $e');
    }
  }

  // ========================================
  // LECTURES
  // ========================================

  /// Récupérer tous les événements (stream temps réel).
  /// Écoute à la fois la table `events` et `registrations` pour que
  /// les cartes se mettent à jour lors d'une inscription ou confirmation.
  Stream<List<Event>> getAllEventsStream() {
    late StreamController<List<Event>> controller;
    StreamSubscription? eventsSub;
    StreamSubscription? regsSub;

    void fetchAndEmit() async {
      try {
        final events = await getAllEvents();
        if (!controller.isClosed) controller.add(events);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    controller = StreamController<List<Event>>(
      onListen: () {
        eventsSub = _supabase
            .from('events')
            .stream(primaryKey: ['id'])
            .listen((_) => fetchAndEmit());
        regsSub = _supabase
            .from('registrations')
            .stream(primaryKey: ['id'])
            .listen((_) => fetchAndEmit());
      },
      onCancel: () {
        eventsSub?.cancel();
        regsSub?.cancel();
        controller.close();
      },
    );

    return controller.stream;
  }

  Future<List<Event>> getAllEvents() async {
    try {
      final data = await _supabase
          .from('events')
          .select(_select)
          .order('date', ascending: true);
      return (data as List).map((e) => Event.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des événements: $e');
    }
  }

  Future<void> updateEventSummary(String eventId, String summary) async {
    try {
      await _supabase
          .from('events')
          .update({'summary': summary})
          .eq('id', eventId);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du compte-rendu: $e');
    }
  }

  Future<Event?> getEvent(String eventId) async {
    try {
      final data = await _supabase
          .from('events')
          .select(_select)
          .eq('id', eventId)
          .maybeSingle();
      return data != null ? Event.fromMap(data) : null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'événement: $e');
    }
  }

  /// Événements auxquels un utilisateur est inscrit (stream)
  Stream<List<Event>> getUserEventsStream(String userId) {
    // Stream les inscriptions de cet user, puis charge les events complets
    return _supabase
        .from('registrations')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .asyncMap((regs) async {
          if (regs.isEmpty) return <Event>[];
          final eventIds = regs
              .where((r) => r['status'] != 'declined')
              .map((r) => r['event_id'] as String)
              .toList();
          if (eventIds.isEmpty) return <Event>[];
          final data = await _supabase
              .from('events')
              .select(_select)
              .inFilter('id', eventIds);
          return (data as List).map((e) => Event.fromMap(e)).toList();
        });
  }

  Future<List<Event>> getUserEvents(String userId) async {
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
          .select(_select)
          .inFilter('id', eventIds);
      return (data as List).map((e) => Event.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des événements utilisateur: $e');
    }
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
          .select(_select)
          .inFilter('id', eventIds);
      return (data as List).map((e) => Event.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des événements confirmés: $e');
    }
  }

  Future<int> countEvents() async {
    try {
      final data = await _supabase.from('events').select('id');
      return (data as List).length;
    } catch (e) {
      throw Exception('Erreur lors du comptage des événements: $e');
    }
  }

  // ========================================
  // GESTION DES INSCRIPTIONS
  // ========================================

  Future<void> registerUserToEvent(String eventId, String userId) async {
    try {
      final event = await getEvent(eventId);
      if (event == null) throw Exception('Événement non trouvé');
      if (event.isFull) throw Exception('Événement complet');

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

  // ========================================
  // GESTION DE LA CONFIRMATION DE PRÉSENCE
  // ========================================

  Future<void> updateEventStatus(String eventId, EventStatus newStatus) async {
    try {
      await _supabase
          .from('events')
          .update({'status': newStatus.name})
          .eq('id', eventId);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut: $e');
    }
  }

  Future<void> confirmUserPresence(String eventId, String userId) async {
    try {
      final event = await getEvent(eventId);
      if (event == null) throw Exception('Événement non trouvé');
      if (!event.registeredUserIds.contains(userId)) {
        throw Exception('Utilisateur non inscrit à cet événement');
      }
      if (event.status != EventStatus.started) {
        throw Exception('L\'événement n\'a pas commencé');
      }

      await _supabase
          .from('registrations')
          .update({'status': 'confirmed', 'responded_at': DateTime.now().toIso8601String()})
          .eq('event_id', eventId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Erreur lors de la confirmation: $e');
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
      throw Exception('Erreur lors de la suppression de confirmation: $e');
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
  // STATISTIQUES
  // ========================================

  Future<Map<String, dynamic>> getEventStats(String eventId) async {
    try {
      final event = await getEvent(eventId);
      if (event == null) throw Exception('Événement non trouvé');
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
        'status': event.status.name,
      };
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }

  Future<List<String>> getRegisteredUsers(String eventId) async {
    try {
      final event = await getEvent(eventId);
      return event?.registeredUserIds ?? [];
    } catch (e) {
      throw Exception('Erreur lors de la récupération des utilisateurs inscrits: $e');
    }
  }

  Future<List<String>> getConfirmedUsers(String eventId) async {
    try {
      final event = await getEvent(eventId);
      return event?.confirmedParticipants ?? [];
    } catch (e) {
      throw Exception('Erreur lors de la récupération des utilisateurs confirmés: $e');
    }
  }

  // ========================================
  // RECHERCHE
  // ========================================

  Future<List<Event>> searchEventsByTheme(String query) async {
    try {
      final data = await _supabase
          .from('events')
          .select(_select)
          .ilike('theme', '%$query%');
      return (data as List).map((e) => Event.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  Future<List<Event>> getUpcomingEvents() async {
    try {
      final data = await _supabase
          .from('events')
          .select(_select)
          .gt('date', DateTime.now().toIso8601String())
          .order('date', ascending: true);
      return (data as List).map((e) => Event.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des événements à venir: $e');
    }
  }

  Future<List<Event>> getPastEvents() async {
    try {
      final data = await _supabase
          .from('events')
          .select(_select)
          .lt('date', DateTime.now().toIso8601String())
          .order('date', ascending: false);
      return (data as List).map((e) => Event.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des événements passés: $e');
    }
  }

  // ========================================
  // INITIALISATION DES ÉVÉNEMENTS PAR DÉFAUT
  // ========================================

  Future<void> initializeDefaultEvents() async {
    try {
      final count = await countEvents();
      if (count > 0) {
        if (kDebugMode) debugPrint('✅ Des événements existent déjà. Initialisation ignorée.');
        return;
      }

      if (kDebugMode) debugPrint('📝 Initialisation des événements par défaut...');
      final now = DateTime.now();
      final events = [
        Event(
          id: '',
          date: now.add(const Duration(days: 7)),
          theme: 'Introduction à Flutter',
          intervenant: 'Jean Dupont',
          entreprise: 'Tech Solutions',
          lieu: 'Paris, France',
          maxParticipants: 30,
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
          status: EventStatus.pending,
        ),
        Event(
          id: '',
          date: now.add(const Duration(days: 21)),
          theme: 'Cloud et Backend avec Supabase',
          intervenant: 'Pierre Bernard',
          entreprise: 'Cloud Experts',
          lieu: 'Bordeaux, France',
          maxParticipants: 20,
          status: EventStatus.pending,
        ),
      ];

      for (final event in events) {
        await createEvent(event);
      }
      if (kDebugMode) debugPrint('✅ ${events.length} événements par défaut créés avec succès!');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Erreur lors de l\'initialisation des événements: $e');
    }
  }

  Future<void> clearAllEvents() async {
    try {
      await _supabase.from('events').delete().neq('id', '');
      if (kDebugMode) debugPrint('✅ Tous les événements ont été supprimés.');
    } catch (e) {
      throw Exception('Erreur lors de la suppression des événements: $e');
    }
  }

}
