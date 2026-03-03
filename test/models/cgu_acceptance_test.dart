import 'package:flutter_test/flutter_test.dart';
import 'package:coentrepreneurs/models/cgu_acceptance.dart';

void main() {
  Map<String, dynamic> baseMap() => {
        'user_id': 'uid-1',
        'has_accepted': true,
        'accepted_date': '2025-03-01T10:00:00.000Z',
        'cgu_version': '1.0',
      };

  group('CGUAcceptance.fromMap', () {
    test('champs de base', () {
      final cgu = CGUAcceptance.fromMap(baseMap());
      expect(cgu.userId, 'uid-1');
      expect(cgu.hasAccepted, isTrue);
      expect(cgu.cguVersion, '1.0');
      expect(cgu.acceptedDate, DateTime.parse('2025-03-01T10:00:00.000Z'));
    });

    test('has_accepted false', () {
      final cgu = CGUAcceptance.fromMap({...baseMap(), 'has_accepted': false});
      expect(cgu.hasAccepted, isFalse);
    });
  });

  group('CGUAcceptance.toMap', () {
    test('roundtrip toMap → fromMap', () {
      final original = CGUAcceptance.fromMap(baseMap());
      final restored = CGUAcceptance.fromMap(original.toMap());
      expect(restored.userId, original.userId);
      expect(restored.hasAccepted, original.hasAccepted);
      expect(restored.cguVersion, original.cguVersion);
      expect(restored.acceptedDate.toIso8601String(),
          original.acceptedDate.toIso8601String());
    });

    test('accepted_date est une string ISO 8601', () {
      final cgu = CGUAcceptance.fromMap(baseMap());
      final map = cgu.toMap();
      expect(map['accepted_date'], isA<String>());
      expect(() => DateTime.parse(map['accepted_date'] as String), returnsNormally);
    });
  });

  group('CGUAcceptance.copyWith', () {
    test('modifie uniquement les champs spécifiés', () {
      final original = CGUAcceptance.fromMap(baseMap());
      final copy = original.copyWith(cguVersion: '2.0');
      expect(copy.cguVersion, '2.0');
      expect(copy.userId, original.userId);
      expect(copy.hasAccepted, original.hasAccepted);
    });

    test('sans paramètre → copie identique', () {
      final original = CGUAcceptance.fromMap(baseMap());
      final copy = original.copyWith();
      expect(copy.userId, original.userId);
      expect(copy.hasAccepted, original.hasAccepted);
      expect(copy.cguVersion, original.cguVersion);
    });

    test('modifie hasAccepted', () {
      final original = CGUAcceptance.fromMap(baseMap());
      final copy = original.copyWith(hasAccepted: false);
      expect(copy.hasAccepted, isFalse);
      expect(original.hasAccepted, isTrue); // immuabilité
    });
  });
}
