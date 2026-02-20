// models/feedback.dart

class Feedback {
  final String id;
  final String eventId;
  final String userId;
  final String userEmail;
  final String userPrenom;
  final String userNom;
  final String whatYouLiked;      // Qu'est-ce qui vous a plu
  final int rating;                 // Note de 0 à 10
  final String whatYouLearned;      // Ce que tu as retenu
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

  /// Convertir vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'userId': userId,
      'userEmail': userEmail,
      'userPrenom': userPrenom,
      'userNom': userNom,
      'whatYouLiked': whatYouLiked,
      'rating': rating,
      'whatYouLearned': whatYouLearned,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Créer à partir d'une Map Firestore
  factory Feedback.fromMap(Map<String, dynamic> data) {
    return Feedback(
      id: data['id'] ?? '',
      eventId: data['eventId'] ?? '',
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userPrenom: data['userPrenom'] ?? '',
      userNom: data['userNom'] ?? '',
      whatYouLiked: data['whatYouLiked'] ?? '',
      rating: data['rating'] ?? 0,
      whatYouLearned: data['whatYouLearned'] ?? '',
      createdAt: data['createdAt'] is DateTime
          ? data['createdAt']
          : DateTime.parse(data['createdAt']?.toString() ?? DateTime.now().toString()),
      updatedAt: data['updatedAt'] is DateTime
          ? data['updatedAt']
          : DateTime.parse(data['updatedAt']?.toString() ?? DateTime.now().toString()),
    );
  }

  /// Copie avec modifications
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
