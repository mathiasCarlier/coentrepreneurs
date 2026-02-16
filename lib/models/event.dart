// models/event.dart - VERSION MISE À JOUR AVEC ACCEPTATIONS
class Event {
  final String id;
  final DateTime date;
  final String theme;
  final String intervenant;
  final String entreprise;
  final String lieu;
  final int maxParticipants;
  final List<String> registeredUserIds; // UIDs des utilisateurs inscrits
  final List<String> confirmedParticipants; // UIDs des utilisateurs ayant accepté leur participation

  Event({
    required this.id,
    required this.date,
    required this.theme,
    required this.intervenant,
    required this.entreprise,
    required this.lieu,
    this.maxParticipants = 30,
    this.registeredUserIds = const [],
    this.confirmedParticipants = const [],
  });

  /// Convertir un document Firestore en Event
  factory Event.fromFirestore(Map<String, dynamic> data, String docId) {
    return Event(
      id: docId,
      date: (data['date'] as dynamic).toDate() ?? DateTime.now(),
      theme: data['theme'] ?? '',
      intervenant: data['intervenant'] ?? '',
      entreprise: data['entreprise'] ?? '',
      lieu: data['lieu'] ?? '',
      maxParticipants: data['maxParticipants'] ?? 30,
      registeredUserIds: List<String>.from(data['registeredUserIds'] ?? []),
      confirmedParticipants: List<String>.from(data['confirmedParticipants'] ?? []),
    );
  }

  /// Convertir Event en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'theme': theme,
      'intervenant': intervenant,
      'entreprise': entreprise,
      'lieu': lieu,
      'maxParticipants': maxParticipants,
      'registeredUserIds': registeredUserIds,
      'confirmedParticipants': confirmedParticipants,
    };
  }

  /// Copier Event avec modifications
  Event copyWith({
    String? id,
    DateTime? date,
    String? theme,
    String? intervenant,
    String? entreprise,
    String? lieu,
    int? maxParticipants,
    List<String>? registeredUserIds,
    List<String>? confirmedParticipants,
  }) {
    return Event(
      id: id ?? this.id,
      date: date ?? this.date,
      theme: theme ?? this.theme,
      intervenant: intervenant ?? this.intervenant,
      entreprise: entreprise ?? this.entreprise,
      lieu: lieu ?? this.lieu,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      registeredUserIds: registeredUserIds ?? this.registeredUserIds,
      confirmedParticipants: confirmedParticipants ?? this.confirmedParticipants,
    );
  }

  /// Formater la date au format français (jj/mm/yyyy)
  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Vérifier si l'intervenant est défini et pas vide
  bool get isDefinedIntervenant {
    return intervenant.isNotEmpty && 
           intervenant.toLowerCase() != 'non défini';
  }

  /// Vérifier si l'entreprise est définie et pas vide
  bool get isDefinedEntreprise {
    return entreprise.isNotEmpty && 
           entreprise.toLowerCase() != 'non défini';
  }

  /// Vérifier si le lieu est défini et pas vide
  bool get isDefinedLieu {
    return lieu.isNotEmpty && 
           lieu.toLowerCase() != 'non défini' &&
           lieu.toLowerCase() != 'en cours de définition';
  }

  /// Obtenir le nombre de participants actuels
  int get currentParticipants => registeredUserIds.length;

  /// Vérifier si l'événement est complet
  bool get isFull => currentParticipants >= maxParticipants;

  /// Vérifier si un utilisateur est inscrit
  bool isUserRegistered(String userId) => registeredUserIds.contains(userId);

  /// Vérifier si l'utilisateur a confirmé sa présence
  bool isUserConfirmed(String userId) => confirmedParticipants.contains(userId);

  /// Obtenir la formule de places disponibles
  String get participantsInfo => '$currentParticipants / $maxParticipants';

  /// Obtenir le pourcentage de places occupées
  double get registrationPercentage => maxParticipants > 0 ? currentParticipants / maxParticipants : 0;
}