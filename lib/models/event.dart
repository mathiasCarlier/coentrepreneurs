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

/// Représente une rencontre/événement de la plateforme.
///
/// Les listes [registeredUserIds], [confirmedParticipants] et [declinedUserIds]
/// sont des tableaux Firestore mis à jour atomiquement via [FieldValue.arrayUnion]
/// / [FieldValue.arrayRemove] dans [RegistrationService].
///
/// [collationMenuText] est optionnel (null = pas de collation).
/// [collationParticipants] contient les userId ayant répondu "oui" au repas.
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
  final String? collationMenuText;           // Description du menu (null = pas de collation)
  final List<String> collationParticipants;  // userId ayant dit "oui" au repas
  final EventStatus status;                  // État de l'événement
  final String? summary;                     // Compte-rendu en Markdown (null = pas encore rédigé)
  final String? description;                 // Description/détails de la rencontre
  final String? linkUrl;                     // Lien externe optionnel
  final String? imageUrl;                    // URL image Firebase Storage
  final String? fileUrl;                     // URL fichier Firebase Storage
  final String? fileName;                    // Nom d'origine du fichier

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
    this.collationMenuText,
    this.collationParticipants = const [],
    this.status = EventStatus.pending,
    this.summary,
    this.description,
    this.linkUrl,
    this.imageUrl,
    this.fileUrl,
    this.fileName,
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
  bool get hasCollation => collationMenuText != null && collationMenuText!.isNotEmpty;
  bool get hasSummary => summary != null && summary!.isNotEmpty;

  bool hasUserChosenCollation(String uid) => collationParticipants.contains(uid);

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
    if (collationMenuText != null && collationMenuText!.isNotEmpty) {
      map['collationMenuText'] = collationMenuText;
    }
    if (collationParticipants.isNotEmpty) {
      map['collationParticipants'] = collationParticipants;
    }
    if (summary != null && summary!.isNotEmpty) {
      map['summary'] = summary;
    }
    if (description != null && description!.isNotEmpty) {
      map['description'] = description;
    }
    if (linkUrl != null && linkUrl!.isNotEmpty) {
      map['linkUrl'] = linkUrl;
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      map['imageUrl'] = imageUrl;
    }
    if (fileUrl != null && fileUrl!.isNotEmpty) {
      map['fileUrl'] = fileUrl;
      if (fileName != null) map['fileName'] = fileName;
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
      collationMenuText: map['collationMenuText'] as String?,
      collationParticipants: List<String>.from(map['collationParticipants'] ?? []),
      status: _statusFromString(map['status'] ?? 'pending'),
      summary: map['summary'] as String?,
      description: map['description'] as String?,
      linkUrl: map['linkUrl'] as String?,
      imageUrl: map['imageUrl'] as String?,
      fileUrl: map['fileUrl'] as String?,
      fileName: map['fileName'] as String?,
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
    String? collationMenuText,
    bool clearCollationMenuText = false,
    List<String>? collationParticipants,
    EventStatus? status,
    String? summary,
    bool clearSummary = false,
    String? description,
    bool clearDescription = false,
    String? linkUrl,
    bool clearLinkUrl = false,
    String? imageUrl,
    bool clearImageUrl = false,
    String? fileUrl,
    bool clearFileUrl = false,
    String? fileName,
    bool clearFileName = false,
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
      collationMenuText: clearCollationMenuText ? null : (collationMenuText ?? this.collationMenuText),
      collationParticipants: collationParticipants ?? this.collationParticipants,
      status: status ?? this.status,
      summary: clearSummary ? null : (summary ?? this.summary),
      description: clearDescription ? null : (description ?? this.description),
      linkUrl: clearLinkUrl ? null : (linkUrl ?? this.linkUrl),
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      fileUrl: clearFileUrl ? null : (fileUrl ?? this.fileUrl),
      fileName: clearFileName ? null : (fileName ?? this.fileName),
    );
  }
}
