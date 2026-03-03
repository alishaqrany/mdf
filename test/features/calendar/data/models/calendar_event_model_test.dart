import 'package:flutter_test/flutter_test.dart';
import 'package:mdf_app/features/calendar/data/models/calendar_event_model.dart';

void main() {
  const tJson = {
    'id': 1,
    'name': 'Quiz Deadline',
    'description': 'Chapter 5 Quiz closes',
    'courseid': 101,
    'coursename': 'Mathematics 101',
    'groupid': 5,
    'userid': 42,
    'modulename': 'quiz',
    'instance': 10,
    'eventtype': 'due',
    'timestart': 1700000000,
    'timeduration': 3600,
    'timemodified': 1699900000,
    'visible': 1,
  };

  group('CalendarEventModel.fromJson', () {
    test('should parse a complete event JSON', () {
      final model = CalendarEventModel.fromJson(tJson);
      expect(model.id, 1);
      expect(model.name, 'Quiz Deadline');
      expect(model.description, 'Chapter 5 Quiz closes');
      expect(model.courseId, 101);
      expect(model.courseName, 'Mathematics 101');
      expect(model.groupId, 5);
      expect(model.userId, 42);
      expect(model.moduleName, 'quiz');
      expect(model.instance, 10);
      expect(model.eventType, 'due');
      expect(model.timeStart, 1700000000);
      expect(model.timeDuration, 3600);
      expect(model.timeModified, 1699900000);
      expect(model.visible, true);
    });

    test('should handle visible=0 as false', () {
      final model = CalendarEventModel.fromJson(const {
        ...{
          'id': 1,
          'name': 'Test',
          'eventtype': 'site',
          'timestart': 0,
          'timeduration': 0,
        },
        'visible': 0,
      });
      expect(model.visible, false);
    });

    test('should default visible to true when null', () {
      final model = CalendarEventModel.fromJson(const {
        'id': 1,
        'name': 'Test',
        'eventtype': 'site',
        'timestart': 0,
        'timeduration': 0,
      });
      // null != 0, so visible = true
      expect(model.visible, true);
    });

    test('should use defaults for missing fields', () {
      final model = CalendarEventModel.fromJson(const {});
      expect(model.id, 0);
      expect(model.name, '');
      expect(model.eventType, 'site');
      expect(model.timeStart, 0);
      expect(model.timeDuration, 0);
      expect(model.description, isNull);
      expect(model.courseId, isNull);
    });
  });

  group('CalendarEventModel.toJson', () {
    test('should produce correct JSON', () {
      final model = CalendarEventModel.fromJson(tJson);
      final json = model.toJson();
      expect(json['id'], 1);
      expect(json['name'], 'Quiz Deadline');
      expect(json['eventtype'], 'due');
      expect(json['timestart'], 1700000000);
      expect(json['timeduration'], 3600);
      expect(json['visible'], 1); // bool -> int
    });

    test('should write visible as 0 when false', () {
      final model = CalendarEventModel.fromJson(const {
        'id': 1,
        'name': 'Hidden',
        'eventtype': 'site',
        'timestart': 0,
        'timeduration': 0,
        'visible': 0,
      });
      expect(model.toJson()['visible'], 0);
    });
  });

  group('CalendarEventModel roundtrip', () {
    test('fromJson → toJson → fromJson preserves data', () {
      final model1 = CalendarEventModel.fromJson(tJson);
      final json = model1.toJson();
      final model2 = CalendarEventModel.fromJson(json);
      expect(model2.id, model1.id);
      expect(model2.name, model1.name);
      expect(model2.eventType, model1.eventType);
      expect(model2.visible, model1.visible);
      expect(model2.timeStart, model1.timeStart);
    });
  });
}
