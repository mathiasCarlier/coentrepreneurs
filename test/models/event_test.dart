import 'package:flutter_test/flutter_test.dart';
import 'package:coentrepreneurs/models/event.dart';

void main() {
  // Map minimale valide pour construire un Event depuis Supabase
  Map<String, dynamic> baseMap() => {
        'id': 'evt-1',
        'date': '2025-06-15T18:00:00.000Z',
        'theme': 'IA & Entrepreneuriat',
        'intervenant': 'Jean Dupont',
        'entreprise': 'TechCo',
        'lieu': 'Paris 8e',
        'max_participants': 30,
        'status': 'pending',
      };

  group('Event.fromMap', () {
    test('champs de base', () {
      final event = Event.fromMap(baseMap());
      expect(event.id, 'evt-1');
      expect(event.theme, 'IA & Entrepreneuriat');
      expect(event.intervenant, 'Jean Dupont');
      expect(event.entreprise, 'TechCo');
      expect(event.lieu, 'Paris 8e');
      expect(event.maxParticipants, 30);
      expect(event.status, EventStatus.pending);
    });

    test('statuts started et finished', () {
      expect(
        Event.fromMap({...baseMap(), 'status': 'started'}).status,
        EventStatus.started,
      );
      expect(
        Event.fromMap({...baseMap(), 'status': 'finished'}).status,
        EventStatus.finished,
      );
    });

    test('statut inconnu → pending par défaut', () {
      expect(
        Event.fromMap({...baseMap(), 'status': 'nope'}).status,
        EventStatus.pending,
      );
    });

    test('champs optionnels null par défaut', () {
      final event = Event.fromMap(baseMap());
      expect(event.summary, isNull);
      expect(event.description, isNull);
      expect(event.linkUrl, isNull);
      expect(event.imageUrl, isNull);
      expect(event.fileUrl, isNull);
      expect(event.fileName, isNull);
      expect(event.collationMenuText, isNull);
    });

    test('listes vides sans registrations', () {
      final event = Event.fromMap(baseMap());
      expect(event.registeredUserIds, isEmpty);
      expect(event.confirmedParticipants, isEmpty);
      expect(event.declinedUserIds, isEmpty);
      expect(event.collationParticipants, isEmpty);
    });

    test('registrations join peuple les listes', () {
      final map = {
        ...baseMap(),
        'registrations': [
          {'user_id': 'u1', 'status': 'registered', 'has_collation': false},
          {'user_id': 'u2', 'status': 'confirmed', 'has_collation': true},
          {'user_id': 'u3', 'status': 'declined', 'has_collation': false},
        ],
      };
      final event = Event.fromMap(map);
      // registered + confirmed sont dans registeredUserIds
      expect(event.registeredUserIds, containsAll(['u1', 'u2']));
      expect(event.confirmedParticipants, ['u2']);
      expect(event.declinedUserIds, ['u3']);
      expect(event.collationParticipants, ['u2']);
    });
  });

  group('Event.toMap', () {
    test('contient tous les champs obligatoires', () {
      final event = Event.fromMap(baseMap());
      final map = event.toMap();
      expect(map['id'], 'evt-1');
      expect(map['theme'], 'IA & Entrepreneuriat');
      expect(map['status'], 'pending');
      expect(map['max_participants'], 30);
    });

    test('file_name présent', () {
      final event = Event.fromMap({
        ...baseMap(),
        'file_url': 'https://example.com/file.pdf',
        'file_name': 'document.pdf',
      });
      expect(event.toMap()['file_name'], 'document.pdf');
      expect(event.toMap()['file_url'], 'https://example.com/file.pdf');
    });

    test('collation_menu_text présent', () {
      final event = Event.fromMap({
        ...baseMap(),
        'collation_menu_text': 'Pizza, Salade',
      });
      expect(event.toMap()['collation_menu_text'], 'Pizza, Salade');
    });
  });

  group('Propriétés calculées', () {
    test('currentParticipants et isFull', () {
      final event = Event.fromMap({
        ...baseMap(),
        'max_participants': 2,
        'registrations': [
          {'user_id': 'u1', 'status': 'registered', 'has_collation': false},
          {'user_id': 'u2', 'status': 'registered', 'has_collation': false},
        ],
      });
      expect(event.currentParticipants, 2);
      expect(event.isFull, isTrue);
    });

    test('registrationPercentage', () {
      final event = Event.fromMap({
        ...baseMap(),
        'max_participants': 4,
        'registrations': [
          {'user_id': 'u1', 'status': 'registered', 'has_collation': false},
        ],
      });
      expect(event.registrationPercentage, 0.25);
    });

    test('formattedDate', () {
      final event = Event.fromMap({...baseMap(), 'date': '2025-03-15T10:00:00.000Z'});
      expect(event.formattedDate, contains('15'));
      expect(event.formattedDate, contains('mar'));
      expect(event.formattedDate, contains('2025'));
    });

    test('hasCollation', () {
      expect(Event.fromMap(baseMap()).hasCollation, isFalse);
      expect(
        Event.fromMap({...baseMap(), 'collation_menu_text': 'Pizza'}).hasCollation,
        isTrue,
      );
      expect(
        Event.fromMap({...baseMap(), 'collation_menu_text': ''}).hasCollation,
        isFalse,
      );
    });

    test('isUserRegistered / isUserConfirmed / canUserConfirm', () {
      final event = Event.fromMap({
        ...baseMap(),
        'status': 'started',
        'registrations': [
          {'user_id': 'u1', 'status': 'registered', 'has_collation': false},
          {'user_id': 'u2', 'status': 'confirmed', 'has_collation': false},
        ],
      });
      expect(event.isUserRegistered('u1'), isTrue);
      expect(event.isUserRegistered('u99'), isFalse);
      expect(event.isUserConfirmed('u2'), isTrue);
      expect(event.isUserConfirmed('u1'), isFalse);
      expect(event.canUserConfirm('u1'), isTrue);  // started + registered
      expect(event.canUserConfirm('u99'), isFalse); // not registered
    });
  });

  group('Event.copyWith', () {
    test('modifie uniquement les champs spécifiés', () {
      final original = Event.fromMap(baseMap());
      final copy = original.copyWith(theme: 'Nouveau thème');
      expect(copy.theme, 'Nouveau thème');
      expect(copy.id, original.id);
      expect(copy.lieu, original.lieu);
    });

    test('clearFileName efface le fileName', () {
      final event = Event.fromMap({...baseMap(), 'file_name': 'doc.pdf'});
      final copy = event.copyWith(clearFileName: true);
      expect(copy.fileName, isNull);
    });

    test('clearCollationMenuText efface le champ', () {
      final event = Event.fromMap({...baseMap(), 'collation_menu_text': 'Sandwich'});
      final copy = event.copyWith(clearCollationMenuText: true);
      expect(copy.collationMenuText, isNull);
    });
  });
}
