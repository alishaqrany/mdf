import 'package:flutter_test/flutter_test.dart';

import 'package:mdf_app/features/courses/data/models/course_model.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  // ═════════════════════════════════════════════
  //  CourseModel
  // ═════════════════════════════════════════════
  group('CourseModel', () {
    group('fromEnrolledCourse', () {
      test('parses full Moodle enrolled course JSON', () {
        final course = CourseModel.fromEnrolledCourse(
          TestFixtures.tEnrolledCourseJson,
        );
        expect(course.id, 1);
        expect(course.shortName, 'MATH101');
        expect(course.fullName, 'Mathematics 101');
        expect(course.displayName, 'Mathematics 101');
        expect(course.summary, '<p>Introduction to mathematics</p>');
        expect(course.summaryFormat, 1);
        expect(course.categoryId, 1);
        expect(course.categoryName, 'Mathematics');
        expect(course.startDate, 1700000000);
        expect(course.endDate, 1730000000);
        expect(course.enrolledUserCount, 45);
        expect(course.visible, true);
        expect(course.progress, 75.0);
        expect(course.completed, false);
        expect(course.isFavourite, true);
        expect(course.lastAccess, 1709000000);
      });

      test('parses overviewfiles image URL', () {
        final course = CourseModel.fromEnrolledCourse(
          TestFixtures.tEnrolledCourseJson,
        );
        expect(course.imageUrl, 'https://img.example.com/course1.jpg');
      });

      test('parses contacts list', () {
        final course = CourseModel.fromEnrolledCourse(
          TestFixtures.tEnrolledCourseJson,
        );
        expect(course.contacts.length, 1);
        expect(course.contacts[0].id, 10);
        expect(course.contacts[0].fullName, 'Dr. Mohammed');
        expect(
          course.contacts[0].profileImageUrl,
          'https://img.example.com/teacher.jpg',
        );
      });

      test('falls back to courseimage when overviewfiles is empty', () {
        final course = CourseModel.fromEnrolledCourse(const {
          'id': 5,
          'shortname': 'TEST',
          'fullname': 'Test Course',
          'overviewfiles': [],
          'courseimage': 'https://img.example.com/fallback.jpg',
        });
        expect(course.imageUrl, 'https://img.example.com/fallback.jpg');
      });

      test('imageUrl is null when no images provided', () {
        final course = CourseModel.fromEnrolledCourse(const {
          'id': 6,
          'shortname': 'NOPIC',
          'fullname': 'No Pic Course',
        });
        expect(course.imageUrl, isNull);
      });

      test('handles missing optional fields gracefully', () {
        final course = CourseModel.fromEnrolledCourse(const {
          'id': 7,
          'shortname': 'MIN',
          'fullname': 'Minimal',
        });
        expect(course.id, 7);
        expect(course.shortName, 'MIN');
        expect(course.displayName, isNull);
        expect(course.summary, isNull);
        expect(course.categoryId, isNull);
        expect(course.progress, isNull);
        expect(course.contacts, isEmpty);
      });

      test('visible is false when value is 0', () {
        final course = CourseModel.fromEnrolledCourse(const {
          'id': 8,
          'shortname': 'HID',
          'fullname': 'Hidden',
          'visible': 0,
        });
        expect(course.visible, false);
      });
    });

    group('fromSearchResult', () {
      test('parses search result JSON', () {
        final course = CourseModel.fromSearchResult(const {
          'id': 10,
          'shortname': 'SRCH',
          'fullname': 'Searched Course',
          'displayname': 'Searched Course',
          'summary': 'A course from search',
          'categoryid': 5,
          'categoryname': 'Category 5',
          'courseimage': 'https://img.example.com/search.jpg',
          'enrolledusercount': 120,
        });
        expect(course.id, 10);
        expect(course.shortName, 'SRCH');
        expect(course.fullName, 'Searched Course');
        expect(course.categoryId, 5);
        expect(course.imageUrl, 'https://img.example.com/search.jpg');
        expect(course.enrolledUserCount, 120);
      });
    });

    group('toJson', () {
      test('produces correct map', () {
        final course = CourseModel.fromEnrolledCourse(
          TestFixtures.tEnrolledCourseJson,
        );
        final json = course.toJson();
        expect(json['id'], 1);
        expect(json['shortname'], 'MATH101');
        expect(json['fullname'], 'Mathematics 101');
        expect(json['category'], 1);
        expect(json['progress'], 75.0);
        expect(json['visible'], 1); // true → 1
        expect(json['isfavourite'], true);
      });

      test('visible converts false to 0', () {
        final course = CourseModel.fromEnrolledCourse(const {
          'id': 8,
          'shortname': 'HID',
          'fullname': 'Hidden',
          'visible': 0,
        });
        expect(course.toJson()['visible'], 0);
      });
    });
  });
}
