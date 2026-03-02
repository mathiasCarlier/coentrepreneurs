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
/// Les listes [registeredUserIds], [confirmedParticipants], [declinedUserIds]
/// et [collationParticipants] sont reconstruites depuis la table `registrations`
/// via le join Supabase (clé `registrations` dans la Map retournée).
class Event {
  final String id;
  final DateTime date;
  final String theme;
  final String intervenant;
  final String entreprise;
  final String lieu;
  final int maxParticipants;
  final List<String> registeredUserIds;
  final List<String> confirmedParticipants;
  final List<String> declinedUserIds;
  final String? collationMenuText;
  final List<String> collationParticipants;
  final EventStatus status;
  final String? summary;
  final String? description;
  final String? linkUrl;
  final String? imageUrl;
  final String? fileUrl;
  final String? fileName;

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

  bool isUserRegistered(String uid) => registeredUserIds.contains(uid);
  bool isUserConfirmed(String uid) => confirmedParticipants.contains(uid);
  bool isUserDeclined(String uid) => declinedUserIds.contains(uid);
  bool canUserConfirm(String uid) =>
      status == EventStatus.started && isUserRegistered(uid);

  bool get isStarted => status == EventStatus.started;
  bool get isFinished => status == EventStatus.finished;
  bool get hasCollation => collationMenuText != null && collationMenuText!.isNotEmpty;
  bool get hasSummary => summary != null && summary!.isNotEmpty;
  bool hasUserChosenCollation(String uid) => collationParticipants.contains(uid);

  /// Convertit vers la Map Supabase (snake_case, sans les listes de participants).
  /// Les participants sont gérés via la table `registrations`.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'theme': theme,
      'intervenant': intervenant,
      'entreprise': entreprise,
      'lieu': lieu,
      'max_participants': maxParticipants,
      'status': status.name,
      'summary': summary,
      'description': description,
      'link_url': linkUrl,
      'image_url': imageUrl,
      'file_url': fileUrl,
    };
  }

  /// Crée un Event depuis une réponse Supabase.
  /// La Map peut contenir une clé `registrations` avec le join des participants.
  factory Event.fromMap(Map<String, dynamic> map) {
    final regs = (map['registrations'] as List<dynamic>?) ?? [];
    final registeredIds = <String>[];
    final confirmedIds = <String>[];
    final declinedIds = <String>[];
    final collationIds = <String>[];

    for (final reg in regs) {
      final userId = reg['user_id'] as String? ?? '';
      final regStatus = reg['status'] as String? ?? '';
      final collation = reg['has_collation'] as bool? ?? false;

      if (regStatus == 'registered' || regStatus == 'confirmed') {
        registeredIds.add(userId);
      }
      if (regStatus == 'confirmed') {
        confirmedIds.add(userId);
      }
      if (regStatus == 'declined') {
        declinedIds.add(userId);
      }
      if (collation) {
        collationIds.add(userId);
      }
    }

    return Event(
      id: map['id'] ?? '',
      date: DateTime.parse(map['date'] as String),
      theme: map['theme'] ?? '',
      intervenant: map['intervenant'] ?? '',
      entreprise: map['entreprise'] ?? '',
      lieu: map['lieu'] ?? '',
      maxParticipants: map['max_participants'] ?? 30,
      registeredUserIds: registeredIds,
      confirmedParticipants: confirmedIds,
      declinedUserIds: declinedIds,
      collationParticipants: collationIds,
      status: _statusFromString(map['status'] ?? 'pending'),
      summary: map['summary'] as String?,
      description: map['description'] as String?,
      linkUrl: map['link_url'] as String?,
      imageUrl: map['image_url'] as String?,
      fileUrl: map['file_url'] as String?,
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
