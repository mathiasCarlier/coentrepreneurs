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

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'hasAccepted': hasAccepted,
      'acceptedDate': acceptedDate.toIso8601String(),
      'cguVersion': cguVersion,
    };
  }

  factory CGUAcceptance.fromMap(Map<String, dynamic> map) {
    return CGUAcceptance(
      userId: map['userId'] as String,
      hasAccepted: map['hasAccepted'] as bool,
      acceptedDate: DateTime.parse(map['acceptedDate'] as String),
      cguVersion: map['cguVersion'] as String,
    );
  }
}
