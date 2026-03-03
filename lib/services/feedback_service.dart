// services/feedback_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coentrepreneurs/models/feedback.dart';

class FeedbackService {
  SupabaseClient get _supabase => Supabase.instance.client;

  // ========================================
  // CRÉER / METTRE À JOUR UN FEEDBACK
  // ========================================

  Future<void> createFeedback({
    required String eventId,
    required String userId,
    required String userEmail,
    required String userPrenom,
    required String userNom,
    required String whatYouLiked,
    required int rating,
    required String whatYouLearned,
  }) async {
    try {
      final feedback = Feedback(
        id: '',
        eventId: eventId,
        userId: userId,
        userEmail: userEmail,
        userPrenom: userPrenom,
        userNom: userNom,
        whatYouLiked: whatYouLiked,
        rating: rating,
        whatYouLearned: whatYouLearned,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _supabase.from('feedbacks').insert(feedback.toMap());
      if (kDebugMode) debugPrint('✅ Feedback créé');
    } catch (e) {
      throw Exception('Erreur lors de la création du feedback: $e');
    }
  }

  Future<void> updateFeedback({
    required String feedbackId,
    required String whatYouLiked,
    required int rating,
    required String whatYouLearned,
  }) async {
    try {
      await _supabase.from('feedbacks').update({
        'what_you_liked': whatYouLiked,
        'rating': rating,
        'what_you_learned': whatYouLearned,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', feedbackId);
      if (kDebugMode) debugPrint('✅ Feedback mis à jour: $feedbackId');
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du feedback: $e');
    }
  }

  // ========================================
  // RÉCUPÉRER LES FEEDBACKS
  // ========================================

  Future<Feedback?> getFeedback(String feedbackId) async {
    try {
      final data = await _supabase
          .from('feedbacks')
          .select()
          .eq('id', feedbackId)
          .maybeSingle();
      return data != null ? Feedback.fromMap(data) : null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du feedback: $e');
    }
  }

  Future<Feedback?> getUserEventFeedback(String eventId, String userId) async {
    try {
      final data = await _supabase
          .from('feedbacks')
          .select()
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();
      return data != null ? Feedback.fromMap(data) : null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du feedback utilisateur: $e');
    }
  }

  Future<List<Feedback>> getEventFeedbacks(String eventId) async {
    try {
      final data = await _supabase
          .from('feedbacks')
          .select()
          .eq('event_id', eventId)
          .order('created_at', ascending: false);
      return (data as List).map((e) => Feedback.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des feedbacks: $e');
    }
  }

  Stream<List<Feedback>> getEventFeedbacksStream(String eventId) {
    return _supabase
        .from('feedbacks')
        .stream(primaryKey: ['id'])
        .eq('event_id', eventId)
        .map((data) => data
            .map((e) => Feedback.fromMap(e))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  // ========================================
  // STATISTIQUES
  // ========================================

  Future<double> getAverageRating(String eventId) async {
    try {
      final data = await _supabase
          .from('feedbacks')
          .select('rating')
          .eq('event_id', eventId);
      if ((data as List).isEmpty) return 0.0;
      double total = 0;
      for (final row in data) {
        total += (row['rating'] as num? ?? 0).toDouble();
      }
      return total / data.length;
    } catch (e) {
      throw Exception('Erreur lors du calcul de la note moyenne: $e');
    }
  }

  Future<int> getFeedbackCount(String eventId) async {
    try {
      final data = await _supabase
          .from('feedbacks')
          .select('id')
          .eq('event_id', eventId);
      return (data as List).length;
    } catch (e) {
      throw Exception('Erreur lors du comptage des feedbacks: $e');
    }
  }

  // ========================================
  // SUPPRIMER
  // ========================================

  Future<void> deleteFeedback(String feedbackId) async {
    try {
      await _supabase.from('feedbacks').delete().eq('id', feedbackId);
      if (kDebugMode) debugPrint('✅ Feedback supprimé: $feedbackId');
    } catch (e) {
      throw Exception('Erreur lors de la suppression du feedback: $e');
    }
  }

  Future<void> deleteEventFeedbacks(String eventId) async {
    try {
      await _supabase.from('feedbacks').delete().eq('event_id', eventId);
      if (kDebugMode) debugPrint('✅ Feedbacks de l\'événement supprimés');
    } catch (e) {
      throw Exception('Erreur lors de la suppression des feedbacks: $e');
    }
  }

  // ========================================
  // VÉRIFICATIONS
  // ========================================

  Future<bool> hasFeedback(String eventId, String userId) async {
    try {
      final data = await _supabase
          .from('feedbacks')
          .select('id')
          .eq('event_id', eventId)
          .eq('user_id', userId);
      return (data as List).isNotEmpty;
    } catch (e) {
      throw Exception('Erreur lors de la vérification du feedback: $e');
    }
  }
}
