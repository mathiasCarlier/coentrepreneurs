// models/invitation.dart - Modèle pour les invitations (CORRIGÉ)

import 'package:cloud_firestore/cloud_firestore.dart';

class Invitation {
  final String id;
  final String eventId;
  final String invitedByUserId; // Utilisateur qui invite
  final String invitedUserEmail; // ✅ EMAIL - Requis pour lier à User
  final String invitedUserPrenom;
  final String invitedUserNom;
  final InvitationStatus status; // pending, accepted, declined
  final DateTime createdAt;
  final DateTime? respondedAt;

  Invitation({
    required this.id,
    required this.eventId,
    required this.invitedByUserId,
    required this.invitedUserEmail, // ✅ Maintenant requis
    required this.invitedUserPrenom,
    required this.invitedUserNom,
    this.status = InvitationStatus.pending,
    required this.createdAt,
    this.respondedAt,
  });

  // ✅ Getters
  String get invitedUserFullName => '$invitedUserPrenom $invitedUserNom';
  bool get isPending => status == InvitationStatus.pending;
  bool get isAccepted => status == InvitationStatus.accepted;
  bool get isDeclined => status == InvitationStatus.declined;

  // ✅ Factory fromMap
  factory Invitation.fromMap(Map<String, dynamic> map) {
    return Invitation(
      id: map['id'] ?? '',
      eventId: map['eventId'] ?? '',
      invitedByUserId: map['invitedByUserId'] ?? '',
      invitedUserEmail: map['invitedUserEmail'] ?? '', // ✅ Récupérer email
      invitedUserPrenom: map['invitedUserPrenom'] ?? '',
      invitedUserNom: map['invitedUserNom'] ?? '',
      status: _statusFromString(map['status'] ?? 'pending'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: (map['respondedAt'] as Timestamp?)?.toDate(),
    );
  }

  // ✅ toMap
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'invitedByUserId': invitedByUserId,
      'invitedUserEmail': invitedUserEmail, // ✅ Sauvegarder email
      'invitedUserPrenom': invitedUserPrenom,
      'invitedUserNom': invitedUserNom,
      'status': status.toString().split('.').last,
      'createdAt': createdAt,
      'respondedAt': respondedAt,
    };
  }

  // ✅ copyWith
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

  // ✅ Helper pour InvitationStatus
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
}

// ✅ Enum pour le statut d'invitation
enum InvitationStatus { pending, accepted, declined }