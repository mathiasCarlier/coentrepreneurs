// models/invitation.dart

class Invitation {
  final String id;
  final String eventId;
  final String invitedByUserId;
  final String invitedUserEmail;
  final String invitedUserPrenom;
  final String invitedUserNom;
  final InvitationStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  Invitation({
    required this.id,
    required this.eventId,
    required this.invitedByUserId,
    required this.invitedUserEmail,
    required this.invitedUserPrenom,
    required this.invitedUserNom,
    this.status = InvitationStatus.pending,
    required this.createdAt,
    this.respondedAt,
  });

  String get invitedUserFullName => '$invitedUserPrenom $invitedUserNom';
  bool get isPending => status == InvitationStatus.pending;
  bool get isAccepted => status == InvitationStatus.accepted;
  bool get isDeclined => status == InvitationStatus.declined;

  /// Pour l'insertion Supabase (sans id — généré par la base)
  Map<String, dynamic> toMap() {
    return {
      'event_id': eventId,
      'invited_by_user_id': invitedByUserId,
      'invited_user_email': invitedUserEmail,
      'invited_user_prenom': invitedUserPrenom,
      'invited_user_nom': invitedUserNom,
      'status': status.name,
    };
  }

  factory Invitation.fromMap(Map<String, dynamic> map) {
    return Invitation(
      id: map['id'] ?? '',
      eventId: map['event_id'] ?? '',
      invitedByUserId: map['invited_by_user_id'] ?? '',
      invitedUserEmail: map['invited_user_email'] ?? '',
      invitedUserPrenom: map['invited_user_prenom'] ?? '',
      invitedUserNom: map['invited_user_nom'] ?? '',
      status: _statusFromString(map['status'] ?? 'pending'),
      createdAt: DateTime.parse(
          map['created_at'] as String? ?? DateTime.now().toIso8601String()),
      respondedAt: map['responded_at'] != null
          ? DateTime.parse(map['responded_at'] as String)
          : null,
    );
  }

  static InvitationStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return InvitationStatus.accepted;
      case 'declined':
        return InvitationStatus.declined;
      default:
        return InvitationStatus.pending;
    }
  }

  Invitation copyWith({
    String? id,
    String? eventId,
    String? invitedByUserId,
    String? invitedUserEmail,
    String? invitedUserPrenom,
    String? invitedUserNom,
    InvitationStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return Invitation(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      invitedByUserId: invitedByUserId ?? this.invitedByUserId,
      invitedUserEmail: invitedUserEmail ?? this.invitedUserEmail,
      invitedUserPrenom: invitedUserPrenom ?? this.invitedUserPrenom,
      invitedUserNom: invitedUserNom ?? this.invitedUserNom,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}

enum InvitationStatus { pending, accepted, declined }
