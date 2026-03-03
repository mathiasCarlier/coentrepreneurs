import 'package:flutter_test/flutter_test.dart';
import 'package:coentrepreneurs/models/user.dart';

void main() {
  Map<String, dynamic> baseMap() => {
        'uid': 'uid-1',
        'email': 'jean@test.fr',
        'nom': 'Dupont',
        'prenom': 'Jean',
        'phone': '0600000000',
        'role': 'adherent',
      };

  group('User.fromMap', () {
    test('champs de base', () {
      final user = User.fromMap(baseMap());
      expect(user.uid, 'uid-1');
      expect(user.email, 'jean@test.fr');
      expect(user.nom, 'Dupont');
      expect(user.prenom, 'Jean');
      expect(user.phone, '0600000000');
      expect(user.role, UserRole.adherent);
    });

    test('rôles admin et invite', () {
      expect(User.fromMap({...baseMap(), 'role': 'admin'}).role, UserRole.admin);
      expect(User.fromMap({...baseMap(), 'role': 'invite'}).role, UserRole.invite);
    });

    test('rôle inconnu → invite par défaut', () {
      expect(User.fromMap({...baseMap(), 'role': 'superadmin'}).role, UserRole.invite);
      expect(User.fromMap({...baseMap(), 'role': null}).role, UserRole.invite);
    });

    test('phone null → chaîne vide', () {
      final user = User.fromMap({...baseMap(), 'phone': null});
      expect(user.phone, '');
    });

    test('champs pro optionnels null par défaut', () {
      final user = User.fromMap(baseMap());
      expect(user.companyName, isNull);
      expect(user.skills, isNull);
      expect(user.professionalAddress, isNull);
      expect(user.website, isNull);
      expect(user.shareProInfo, isFalse);
    });

    test('champs pro renseignés', () {
      final user = User.fromMap({
        ...baseMap(),
        'companyName': 'MaSociété',
        'skills': 'Flutter, Dart',
        'professionalAddress': 'Paris',
        'website': 'https://example.com',
        'shareProInfo': true,
      });
      expect(user.companyName, 'MaSociété');
      expect(user.skills, 'Flutter, Dart');
      expect(user.shareProInfo, isTrue);
    });
  });

  group('User.toMap', () {
    test('roundtrip toMap → fromMap', () {
      final original = User(
        uid: 'uid-1',
        email: 'jean@test.fr',
        nom: 'Dupont',
        prenom: 'Jean',
        phone: '0600000000',
        role: UserRole.admin,
        companyName: 'TechCo',
        shareProInfo: true,
      );
      final map = original.toMap();
      final restored = User.fromMap(map);
      expect(restored.uid, original.uid);
      expect(restored.email, original.email);
      expect(restored.role, UserRole.admin);
      expect(restored.companyName, original.companyName);
      expect(restored.shareProInfo, isTrue);
    });

    test('rôle sérialisé en string', () {
      final user = User(uid: 'u', email: 'e@e.fr', nom: 'N', prenom: 'P', role: UserRole.admin);
      expect(user.toMap()['role'], 'admin');
    });
  });

  group('User.copyWith', () {
    test('modifie uniquement les champs spécifiés', () {
      final original = User.fromMap(baseMap());
      final copy = original.copyWith(email: 'autre@test.fr');
      expect(copy.email, 'autre@test.fr');
      expect(copy.uid, original.uid);
      expect(copy.nom, original.nom);
    });

    test('sans paramètre → copie identique', () {
      final original = User.fromMap(baseMap());
      final copy = original.copyWith();
      expect(copy.uid, original.uid);
      expect(copy.role, original.role);
    });
  });
}
