import 'package:flutter_test/flutter_test.dart';
import 'package:message_board/models/message.dart';
import 'package:message_board/models/user_record.dart';

void main() {
  group('UserRecord Model Tests', () {
    test('Constructs UserRecord and validates fullName', () {
      final user = UserRecord(
        uid: 'test_uid_123',
        firstName: 'Ada',
        lastName: 'Lovelace',
        role: 'Student',
        registrationDateTime: DateTime(2026, 11, 15, 12, 0, 0),
      );

      expect(user.uid, 'test_uid_123');
      expect(user.fullName, 'Ada Lovelace');
      expect(user.role, 'Student');
      expect(user.registrationDateTime, isNotNull);
    });

    test('UserRecord toMap contains all 5 required fields', () {
      final user = UserRecord(
        uid: 'test_uid_456',
        firstName: 'Grace',
        lastName: 'Hopper',
        role: 'Faculty',
        registrationDateTime: DateTime(2026, 11, 15, 12, 0, 0),
      );

      final map = user.toMap(forCreate: false);
      expect(map.containsKey('uid'), isTrue);
      expect(map.containsKey('firstName'), isTrue);
      expect(map.containsKey('lastName'), isTrue);
      expect(map.containsKey('role'), isTrue);
      expect(map.containsKey('registrationDateTime'), isTrue);
      expect(map['firstName'], 'Grace');
      expect(map['lastName'], 'Hopper');
      expect(map['role'], 'Faculty');
    });
  });

  group('Message Model Tests', () {
    test('Constructs Message with schema versioning and author ownership', () {
      final msg = Message(
        id: 'msg_001',
        text: 'Hello from Flutter!',
        authorUid: 'user_ada_001',
        authorName: 'Ada',
        createdAt: DateTime(2026, 11, 15, 14, 0, 0),
        schemaVersion: 2,
      );

      expect(msg.id, 'msg_001');
      expect(msg.text, 'Hello from Flutter!');
      expect(msg.authorUid, 'user_ada_001');
      expect(msg.isEdited, isFalse);
      expect(msg.schemaVersion, 2);
    });

    test('Message toMapForCreate includes server timestamp and schemaVersion', () {
      final msg = Message(
        id: 'new_doc',
        text: 'Live stream test',
        authorUid: 'user_grace_002',
        authorName: 'Grace',
      );

      final map = msg.toMapForCreate();
      expect(map['text'], 'Live stream test');
      expect(map['authorUid'], 'user_grace_002');
      expect(map['authorName'], 'Grace');
      expect(map.containsKey('createdAt'), isTrue);
      expect(map['schemaVersion'], 2);
    });
  });
}
