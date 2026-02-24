import 'package:cloud_firestore/cloud_firestore.dart';

/// Cycle de vie d'une rencontre.
///
/// - [pending] : inscriptions ouvertes, aucune action de l'organisateur requise.
/// - [started] : rencontre en cours ; les inscrits peuvent confirmer leur présence.
/// - [finished] : rencontre terminée ; les retours (feedback) peuvent être collectés.
enum EventStatus {
  pending,
  started,
  finished,
}

/// Élément du menu de collation (nom + prix).
class CollationItem {
  final String nom;
  final double prix;

  const CollationItem({required this.nom, required this.prix});

  Map<String, dynamic> toMap() => {'nom': nom, 'prix': prix};

  factory CollationItem.fromMap(Map<String, dynamic> map) {
    return CollationItem(
      nom: map['nom'] ?? '',
      prix: (map['prix'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Représente une rencontre/événement de la plateforme.
///
/// Les listes [registeredUserIds], [confirmedParticipants] et [declinedUserIds]
/// sont des tableaux Firestore mis à jour atomiquement via [FieldValue.arrayUnion]
/// / [FieldValue.arrayRemove] dans [RegistrationService].
///
/// [collationMenu] est optionnel (null = pas de collation).
/// [collationParticipants] mappe chaque userId vers les indices des plats choisis.
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
  final List<String> declinedUserIds;        // Ayant refusé
  final List<CollationItem>? collationMenu;  // Menu collation (null = pas de collation)
  final Map<String, List<int>> collationParticipants; // userId → indices plats choisis
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
    this.declinedUserIds = const [],
    this.collationMenu,
    this.collationParticipants = const {},
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

  // ✅ Vérifier si utilisateur a refusé la rencontre
  bool isUserDeclined(String uid) => declinedUserIds.contains(uid);

  // ✅ Vérifier si utilisateur peut confirmer (inscrit + événement commencé)
  bool canUserConfirm(String uid) =>
      status == EventStatus.started && isUserRegistered(uid);

  // ✅ Vérifier si événement est commencé
  bool get isStarted => status == EventStatus.started;

  // ✅ Vérifier si événement est terminé
  bool get isFinished => status == EventStatus.finished;

  // ✅ Collation
  bool get hasCollation => collationMenu != null && collationMenu!.isNotEmpty;

  bool hasUserChosenCollation(String uid) => collationParticipants.containsKey(uid);

  List<CollationItem> getUserCollationItems(String uid) {
    if (!hasCollation || !collationParticipants.containsKey(uid)) return [];
    return collationParticipants[uid]!
        .where((i) => i >= 0 && i < collationMenu!.length)
        .map((i) => collationMenu![i])
        .toList();
  }

  double getUserCollationTotal(String uid) {
    return getUserCollationItems(uid).fold(0.0, (total, item) => total + item.prix);
  }

  // ✅ Conversion vers/depuis Firestore
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'date': date,
      'theme': theme,
      'intervenant': intervenant,
      'entreprise': entreprise,
      'lieu': lieu,
      'maxParticipants': maxParticipants,
      'registeredUserIds': registeredUserIds,
      'confirmedParticipants': confirmedParticipants,
      'declinedUserIds': declinedUserIds,
      'status': status.toString().split('.').last,
    };
    if (collationMenu != null) {
      map['collationMenu'] = collationMenu!.map((e) => e.toMap()).toList();
    }
    if (collationParticipants.isNotEmpty) {
      map['collationParticipants'] = collationParticipants;
    }
    return map;
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
      declinedUserIds: List<String>.from(map['declinedUserIds'] ?? []),
      collationMenu: map['collationMenu'] != null
          ? (map['collationMenu'] as List)
              .map((e) => CollationItem.fromMap(Map<String, dynamic>.from(e)))
              .toList()
          : null,
      collationParticipants: map['collationParticipants'] != null
          ? (map['collationParticipants'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, List<int>.from(value)),
            )
          : {},
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
    List<String>? declinedUserIds,
    List<CollationItem>? collationMenu,
    bool clearCollationMenu = false,
    Map<String, List<int>>? collationParticipants,
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
      declinedUserIds: declinedUserIds ?? this.declinedUserIds,
      collationMenu: clearCollationMenu ? null : (collationMenu ?? this.collationMenu),
      collationParticipants: collationParticipants ?? this.collationParticipants,
      status: status ?? this.status,
    );
  }
}
