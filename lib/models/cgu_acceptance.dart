// models/cgu_acceptance.dart

class CGUAcceptance {
  final String userId;
  final bool hasAccepted;
  final DateTime acceptedDate;
  final String cguVersion;

  CGUAcceptance({
    required this.userId,
    required this.hasAccepted,
    required this.acceptedDate,
    required this.cguVersion,
  });

  /// Pour l'upsert Supabase
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'has_accepted': hasAccepted,
      'accepted_date': acceptedDate.toIso8601String(),
      'cgu_version': cguVersion,
    };
  }

  factory CGUAcceptance.fromMap(Map<String, dynamic> map) {
    return CGUAcceptance(
      userId: map['user_id'] as String,
      hasAccepted: map['has_accepted'] as bool,
      acceptedDate: DateTime.parse(map['accepted_date'] as String),
      cguVersion: map['cgu_version'] as String,
    );
  }
}
