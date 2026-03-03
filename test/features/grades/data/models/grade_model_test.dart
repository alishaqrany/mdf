import 'package:flutter_test/flutter_test.dart';
import 'package:mdf_app/features/grades/data/models/grade_model.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  // ═════════════════════════════════════════════
  //  GradeItemModel
  // ═════════════════════════════════════════════
  group('GradeItemModel', () {
    test('fromJson parses all fields', () {
      final item = GradeItemModel.fromJson(TestFixtures.tGradeItemJson);
      expect(item.id, 1);
      expect(item.itemName, 'Quiz 1');
      expect(item.itemType, 'mod');
      expect(item.itemModule, 'quiz');
      expect(item.courseId, 1);
      expect(item.gradeRaw, 85.0);
      expect(item.gradeMin, 0.0);
      expect(item.gradeMax, 100.0);
      expect(item.percentageFormatted, 85.0);
      expect(item.feedback, isNull);
    });

    test('fromJson with missing fields uses defaults', () {
      final item = GradeItemModel.fromJson(const {});
      expect(item.id, 0);
      expect(item.itemName, '');
      expect(item.itemType, isNull);
      expect(item.gradeRaw, isNull);
    });

    test('fromJson handles numeric string conversions', () {
      final item = GradeItemModel.fromJson(const {
        'id': 5,
        'itemname': 'Test',
        'graderaw': 95,
        'grademin': 0,
        'grademax': 100,
      });
      expect(item.gradeRaw, 95.0);
      expect(item.gradeMin, 0.0);
      expect(item.gradeMax, 100.0);
    });

    test('toJson produces correct map', () {
      final item = GradeItemModel.fromJson(TestFixtures.tGradeItemJson);
      final json = item.toJson();
      expect(json['id'], 1);
      expect(json['itemname'], 'Quiz 1');
      expect(json['itemtype'], 'mod');
      expect(json['itemmodule'], 'quiz');
      expect(json['courseid'], 1);
      expect(json['graderaw'], 85.0);
    });

    test('toJson → fromJson roundtrip', () {
      final original = GradeItemModel.fromJson(TestFixtures.tGradeItemJson);
      final json = original.toJson();
      final restored = GradeItemModel.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.itemName, original.itemName);
      expect(restored.gradeRaw, original.gradeRaw);
      expect(restored.gradeMax, original.gradeMax);
    });

    test('fromJson with feedback', () {
      final item = GradeItemModel.fromJson(const {
        'id': 3,
        'itemname': 'Assignment 1',
        'feedback': '<p>Great work!</p>',
      });
      expect(item.feedback, '<p>Great work!</p>');
    });
  });

  // ═════════════════════════════════════════════
  //  CourseGradeModel
  // ═════════════════════════════════════════════
  group('CourseGradeModel', () {
    test('fromJson parses all fields', () {
      final grade = CourseGradeModel.fromJson(TestFixtures.tCourseGradeJson);
      expect(grade.courseId, 1);
      expect(grade.courseName, 'Mathematics 101');
      expect(grade.grade, 88.5);
      expect(grade.rank, 3);
    });

    test('fromJson with missing fields', () {
      final grade = CourseGradeModel.fromJson(const {});
      expect(grade.courseId, 0);
      expect(grade.courseName, '');
      expect(grade.grade, isNull);
      expect(grade.rank, isNull);
    });

    test('fromJson prefers coursename over fullname', () {
      final grade = CourseGradeModel.fromJson(const {
        'courseid': 5,
        'coursename': 'Primary Name',
        'fullname': 'Fallback Name',
      });
      expect(grade.courseName, 'Primary Name');
    });

    test('fromJson falls back to fullname', () {
      final grade = CourseGradeModel.fromJson(const {
        'courseid': 5,
        'fullname': 'Fallback Name',
      });
      expect(grade.courseName, 'Fallback Name');
    });

    test('toJson produces correct map', () {
      final grade = CourseGradeModel.fromJson(TestFixtures.tCourseGradeJson);
      final json = grade.toJson();
      expect(json['courseid'], 1);
      expect(json['coursename'], 'Mathematics 101');
      expect(json['grade'], 88.5);
      expect(json['rank'], 3);
    });

    test('toJson → fromJson roundtrip', () {
      final original = CourseGradeModel.fromJson(TestFixtures.tCourseGradeJson);
      final json = original.toJson();
      final restored = CourseGradeModel.fromJson(json);
      expect(restored.courseId, original.courseId);
      expect(restored.courseName, original.courseName);
      expect(restored.grade, original.grade);
      expect(restored.rank, original.rank);
    });
  });
}
