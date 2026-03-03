import 'package:flutter_test/flutter_test.dart';
import 'package:mdf_app/features/messaging/data/models/message_model.dart';

void main() {
  group('MessageModel.fromJson', () {
    test('should parse a complete message JSON', () {
      final model = MessageModel.fromJson(const {
        'id': 10,
        'useridfrom': 5,
        'text': 'Hello world',
        'timecreated': 1700000000,
        'isread': true,
      });
      expect(model.id, 10);
      expect(model.userIdFrom, 5);
      expect(model.text, 'Hello world');
      expect(model.timeCreated, 1700000000);
      expect(model.isRead, true);
    });

    test('should handle null optional fields', () {
      final model = MessageModel.fromJson(const {'id': 1, 'useridfrom': 2});
      expect(model.text, isNull);
      expect(model.timeCreated, isNull);
      expect(model.isRead, isNull);
    });

    test('should default useridfrom to 0 when null', () {
      final model = MessageModel.fromJson(const {'id': 1});
      expect(model.userIdFrom, 0);
    });
  });

  group('ConversationMemberModel.fromJson', () {
    test('should parse member JSON', () {
      final model = ConversationMemberModel.fromJson(const {
        'id': 42,
        'fullname': 'Alice Smith',
        'profileimageurl': 'https://example.com/alice.png',
        'isonline': true,
      });
      expect(model.id, 42);
      expect(model.fullName, 'Alice Smith');
      expect(model.profileImageUrl, 'https://example.com/alice.png');
      expect(model.isOnline, true);
    });

    test('should handle missing optional fields', () {
      final model = ConversationMemberModel.fromJson(const {
        'id': 1,
        'fullname': 'Bob',
      });
      expect(model.profileImageUrl, isNull);
      expect(model.isOnline, isNull);
    });

    test('should default fullname to empty string', () {
      final model = ConversationMemberModel.fromJson(const {'id': 1});
      expect(model.fullName, '');
    });
  });

  group('ConversationModel.fromJson', () {
    test('should parse full conversation with members and messages', () {
      final model = ConversationModel.fromJson(const {
        'id': 100,
        'name': 'Study Group Chat',
        'type': 2,
        'membercount': 3,
        'ismuted': false,
        'isfavourite': true,
        'isread': false,
        'unreadcount': 5,
        'members': [
          {'id': 1, 'fullname': 'Alice'},
          {'id': 2, 'fullname': 'Bob'},
        ],
        'messages': [
          {'id': 1, 'useridfrom': 1, 'text': 'Hi!'},
        ],
      });
      expect(model.id, 100);
      expect(model.name, 'Study Group Chat');
      expect(model.type, 2);
      expect(model.memberCount, 3);
      expect(model.isMuted, false);
      expect(model.isFavourite, true);
      expect(model.isRead, false);
      expect(model.unreadCount, 5);
      expect(model.members, hasLength(2));
      expect(model.members[0].fullName, 'Alice');
      expect(model.messages, hasLength(1));
      expect(model.messages[0].text, 'Hi!');
    });

    test('should handle empty members and messages', () {
      final model = ConversationModel.fromJson(const {'id': 1});
      expect(model.members, isEmpty);
      expect(model.messages, isEmpty);
      expect(model.memberCount, 0);
      expect(model.unreadCount, 0);
      expect(model.isRead, true);
    });

    test('should default boolean fields', () {
      final model = ConversationModel.fromJson(const {'id': 1});
      expect(model.isMuted, false);
      expect(model.isFavourite, false);
    });
  });
}
