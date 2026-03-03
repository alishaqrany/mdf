import 'package:flutter_test/flutter_test.dart';
import 'package:mdf_app/features/notifications/data/models/notification_model.dart';

void main() {
  const tJson = {
    'id': 1,
    'useridfrom': 10,
    'useridto': 20,
    'subject': 'Assignment graded',
    'shortenedsubject': 'Assignment graded short',
    'fullmessage': 'Your assignment has been graded.',
    'contexturl': 'https://moodle.example.com/mod/assign/view.php?id=5',
    'contexturlname': 'View assignment',
    'component': 'mod_assign',
    'eventtype': 'assign_notification',
    'timecreated': 1700000000,
    'read': true,
    'userfromfullname': 'Prof. Jones',
    'userfromprofileurl': 'https://example.com/prof.png',
  };

  group('AppNotificationModel.fromJson', () {
    test('should parse a complete notification JSON', () {
      final model = AppNotificationModel.fromJson(tJson);
      expect(model.id, 1);
      expect(model.userIdFrom, 10);
      expect(model.userIdTo, 20);
      expect(model.subject, 'Assignment graded');
      expect(model.shortMessage, 'Assignment graded short');
      expect(model.fullMessage, 'Your assignment has been graded.');
      expect(
        model.contextUrl,
        'https://moodle.example.com/mod/assign/view.php?id=5',
      );
      expect(model.contextUrlName, 'View assignment');
      expect(model.component, 'mod_assign');
      expect(model.eventType, 'assign_notification');
      expect(model.timeCreated, 1700000000);
      expect(model.isRead, true);
      expect(model.userFromFullName, 'Prof. Jones');
      expect(model.userFromPictureUrl, 'https://example.com/prof.png');
    });

    test('should fall back to smallmessage when shortenedsubject is null', () {
      final model = AppNotificationModel.fromJson(const {
        'id': 1,
        'useridfrom': 0,
        'useridto': 0,
        'smallmessage': 'Fallback message',
      });
      expect(model.shortMessage, 'Fallback message');
    });

    test('should detect read status from timeread', () {
      final model = AppNotificationModel.fromJson(const {
        'id': 1,
        'useridfrom': 0,
        'useridto': 0,
        'timeread': 1700500000,
      });
      expect(model.isRead, true);
    });

    test('should be unread when no read or timeread', () {
      final model = AppNotificationModel.fromJson(const {
        'id': 1,
        'useridfrom': 0,
        'useridto': 0,
      });
      expect(model.isRead, false);
    });

    test('should handle missing optional fields', () {
      final model = AppNotificationModel.fromJson(const {
        'id': 2,
        'useridfrom': 0,
        'useridto': 0,
      });
      expect(model.subject, isNull);
      expect(model.shortMessage, isNull);
      expect(model.fullMessage, isNull);
      expect(model.contextUrl, isNull);
      expect(model.component, isNull);
      expect(model.timeCreated, isNull);
      expect(model.userFromFullName, isNull);
    });
  });

  group('AppNotificationModel.toJson', () {
    test('should produce correct JSON', () {
      final model = AppNotificationModel.fromJson(tJson);
      final json = model.toJson();
      expect(json['id'], 1);
      expect(json['useridfrom'], 10);
      expect(json['useridto'], 20);
      expect(json['subject'], 'Assignment graded');
      expect(json['smallmessage'], 'Assignment graded short');
      expect(json['fullmessage'], 'Your assignment has been graded.');
      expect(json['read'], true);
    });
  });

  group('AppNotificationModel roundtrip', () {
    test('fromJson → toJson → fromJson preserves data', () {
      final model1 = AppNotificationModel.fromJson(tJson);
      final json = model1.toJson();
      // toJson uses 'smallmessage' + 'read', so fromJson will use fallback path
      final model2 = AppNotificationModel.fromJson(json);
      expect(model2.id, model1.id);
      expect(model2.userIdFrom, model1.userIdFrom);
      expect(model2.isRead, model1.isRead);
      expect(model2.component, model1.component);
    });
  });
}
