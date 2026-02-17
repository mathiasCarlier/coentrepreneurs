// models/event.dart - VERSION AMÉLIORÉE AVEC ÉTAT
import 'package:cloud_firestore/cloud_firestore.dart';

enum EventStatus {
  pending,    // En attente - inscriptions ouvertes
  started,    // Commencé - confirmations ouvertes
  finished,   // Terminé
}

class Event {
  final String id;
  final DateTime date;
  final String theme;
  final String intervenant;
  final String entreprise;
  final String lieu;
  final int maxParticipants;
  final List<String> registeredUserIds;      // Inscrits
  final List<String> confirmedParticipants;  // Confirmés présents
  final EventStatus status;                   // État de l'événement

  Event({
    required this.id,
    required this.date,
    required this.theme,
    required this.intervenant,
    required this.entreprise,
    required this.lieu,
    required this.maxParticipants,
    this.registeredUserIds = const [],
    this.confirmedParticipants = const [],
    this.status = EventStatus.pending,
  });

  // ✅ Getters pour simplifier le code
  int get currentParticipants => registeredUserIds.length;
  bool get isFull => currentParticipants >= maxParticipants;
  double get registrationPercentage => 
      maxParticipants > 0 ? currentParticipants / maxParticipants : 0;
  
  String get formattedDate {
    final months = ['jan', 'fév', 'mar', 'avr', 'mai', 'jun', 
                   'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  bool get isDefinedIntervenant => intervenant.isNotEmpty;
  bool get isDefinedEntreprise => entreprise.isNotEmpty;
  bool get isDefinedLieu => lieu.isNotEmpty;

  // ✅ Vérifier si utilisateur est inscrit
  bool isUserRegistered(String uid) => registeredUserIds.contains(uid);

  // ✅ Vérifier si utilisateur a confirmé sa présence
  bool isUserConfirmed(String uid) => confirmedParticipants.contains(uid);

  // ✅ Vérifier si utilisateur peut confirmer (inscrit + événement commencé)
  bool canUserConfirm(String uid) => 
      status == EventStatus.started && isUserRegistered(uid);

  // ✅ Vérifier si événement est commencé
  bool get isStarted => status == EventStatus.started;

  // ✅ Vérifier si événement est terminé
  bool get isFinished => status == EventStatus.finished;

  // ✅ Conversion vers/depuis Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'theme': theme,
      'intervenant': intervenant,
      'entreprise': entreprise,
      'lieu': lieu,
      'maxParticipants': maxParticipants,
      'registeredUserIds': registeredUserIds,
      'confirmedParticipants': confirmedParticipants,
      'status': status.toString().split('.').last, // 'pending', 'started', 'finished'
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      theme: map['theme'] ?? '',
      intervenant: map['intervenant'] ?? '',
      entreprise: map['entreprise'] ?? '',
      lieu: map['lieu'] ?? '',
      maxParticipants: map['maxParticipants'] ?? 30,
      registeredUserIds: List<String>.from(map['registeredUserIds'] ?? []),
      confirmedParticipants: List<String>.from(map['confirmedParticipants'] ?? []),
      status: _statusFromString(map['status'] ?? 'pending'),
    );
  }

  static EventStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'started':
        return EventStatus.started;
      case 'finished':
        return EventStatus.finished;
      default:
        return EventStatus.pending;
    }
  }

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
    EventStatus? status,
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
      status: status ?? this.status,
    );
  }
}