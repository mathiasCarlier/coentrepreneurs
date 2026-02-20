// services/feedback_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:coentrepreneurs/models/feedback.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========================================
  // 📝 CRÉER/METTRE À JOUR UN FEEDBACK
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
      final docRef = _firestore.collection('feedbacks').doc();
      final feedback = Feedback(
        id: docRef.id,
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
      await docRef.set(feedback.toMap());
      debugPrint('✅ Feedback créé: ${docRef.id}');
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
      await _firestore.collection('feedbacks').doc(feedbackId).update({
        'whatYouLiked': whatYouLiked,
        'rating': rating,
        'whatYouLearned': whatYouLearned,
        'updatedAt': DateTime.now(),
      });
      debugPrint('✅ Feedback mis à jour: $feedbackId');
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du feedback: $e');
    }
  }

  // ========================================
  // 🔍 RÉCUPÉRER LES FEEDBACKS
  // ========================================

  Future<Feedback?> getFeedback(String feedbackId) async {
    try {
      final doc = await _firestore.collection('feedbacks').doc(feedbackId).get();
      return doc.exists ? Feedback.fromMap(doc.data()!) : null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du feedback: $e');
    }
  }

  Future<Feedback?> getUserEventFeedback(String eventId, String userId) async {
    try {
      final snapshot = await _firestore
          .collection('feedbacks')
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      return Feedback.fromMap(snapshot.docs.first.data());
    } catch (e) {
      throw Exception('Erreur lors de la récupération du feedback utilisateur: $e');
    }
  }

  Future<List<Feedback>> getEventFeedbacks(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection('feedbacks')
          .where('eventId', isEqualTo: eventId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Feedback.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des feedbacks: $e');
    }
  }

  Stream<List<Feedback>> getEventFeedbacksStream(String eventId) {
    return _firestore
        .collection('feedbacks')
        .where('eventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Feedback.fromMap(doc.data())).toList());
  }

  // ========================================
  // 📊 STATISTIQUES
  // ========================================

  Future<double> getAverageRating(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection('feedbacks')
          .where('eventId', isEqualTo: eventId)
          .get();
      
      if (snapshot.docs.isEmpty) return 0.0;
      
      double total = 0;
      for (var doc in snapshot.docs) {
        total += doc['rating'] ?? 0;
      }
      return total / snapshot.docs.length;
    } catch (e) {
      throw Exception('Erreur lors du calcul de la note moyenne: $e');
    }
  }

  Future<int> getFeedbackCount(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection('feedbacks')
          .where('eventId', isEqualTo: eventId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Erreur lors du comptage des feedbacks: $e');
    }
  }

  // ========================================
  // 🗑️ SUPPRIMER
  // ========================================

  Future<void> deleteFeedback(String feedbackId) async {
    try {
      await _firestore.collection('feedbacks').doc(feedbackId).delete();
      debugPrint('✅ Feedback supprimé: $feedbackId');
    } catch (e) {
      throw Exception('Erreur lors de la suppression du feedback: $e');
    }
  }

  Future<void> deleteEventFeedbacks(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection('feedbacks')
          .where('eventId', isEqualTo: eventId)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('✅ Feedbacks de l\'événement supprimés');
    } catch (e) {
      throw Exception('Erreur lors de la suppression des feedbacks: $e');
    }
  }

  // ========================================
  // 🔍 VÉRIFICATIONS
  // ========================================

  Future<bool> hasFeedback(String eventId, String userId) async {
    try {
      final snapshot = await _firestore
          .collection('feedbacks')
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Erreur lors de la vérification du feedback: $e');
    }
  }
}
