// models/feedback.dart

class Feedback {
  final String id;
  final String eventId;
  final String userId;
  final String userEmail;
  final String userPrenom;
  final String userNom;
  final String whatYouLiked;
  final int rating;
  final String whatYouLearned;
  final DateTime createdAt;
  final DateTime updatedAt;

  Feedback({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userEmail,
    required this.userPrenom,
    required this.userNom,
    required this.whatYouLiked,
    required this.rating,
    required this.whatYouLearned,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Pour l'insertion Supabase (sans id — généré par la base)
  Map<String, dynamic> toMap() {
    return {
      'event_id': eventId,
      'user_id': userId,
      'user_email': userEmail,
      'user_prenom': userPrenom,
      'user_nom': userNom,
      'what_you_liked': whatYouLiked,
      'rating': rating,
      'what_you_learned': whatYouLearned,
    };
  }

  factory Feedback.fromMap(Map<String, dynamic> data) {
    return Feedback(
      id: data['id'] ?? '',
      eventId: data['event_id'] ?? '',
      userId: data['user_id'] ?? '',
      userEmail: data['user_email'] ?? '',
      userPrenom: data['user_prenom'] ?? '',
      userNom: data['user_nom'] ?? '',
      whatYouLiked: data['what_you_liked'] ?? '',
      rating: data['rating'] ?? 0,
      whatYouLearned: data['what_you_learned'] ?? '',
      createdAt: DateTime.parse(
          data['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          data['updated_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Feedback copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? userEmail,
    String? userPrenom,
    String? userNom,
    String? whatYouLiked,
    int? rating,
    String? whatYouLearned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Feedback(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userPrenom: userPrenom ?? this.userPrenom,
      userNom: userNom ?? this.userNom,
      whatYouLiked: whatYouLiked ?? this.whatYouLiked,
      rating: rating ?? this.rating,
      whatYouLearned: whatYouLearned ?? this.whatYouLearned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
