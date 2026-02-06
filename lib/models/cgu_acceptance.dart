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
      // Stockage de la date en ISO string pour une compatibilité simple
      // entre Firestore et l'application. Si vous préférez un `Timestamp`
      // Firestore natif, adaptez `CGUService` en conséquence.
      'acceptedDate': acceptedDate.toIso8601String(),
      'cguVersion': cguVersion,
    };
  }

  factory CGUAcceptance.fromMap(Map<String, dynamic> map) {
    return CGUAcceptance(
      userId: map['userId'] as String,
      hasAccepted: map['hasAccepted'] as bool,
      // Lecture de la date depuis la chaîne ISO. Si le document stocke
      // un `Timestamp`, adaptez la logique ici.
      acceptedDate: DateTime.parse(map['acceptedDate'] as String),
      cguVersion: map['cguVersion'] as String,
    );
  }
}
