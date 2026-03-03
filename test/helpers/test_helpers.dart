/// Shared test helpers, fixtures and mocks for MDF app unit/widget tests.
library;

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mdf_app/features/auth/domain/entities/user.dart';
import 'package:mdf_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:mdf_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:mdf_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mdf_app/features/auth/domain/usecases/check_auth_usecase.dart';
import 'package:mdf_app/features/courses/domain/entities/course.dart';
import 'package:mdf_app/features/courses/domain/repositories/courses_repository.dart';
import 'package:mdf_app/features/courses/domain/usecases/get_enrolled_courses_usecase.dart';
import 'package:mdf_app/features/courses/domain/usecases/search_courses_usecase.dart';
import 'package:mdf_app/features/grades/domain/entities/grade.dart';
import 'package:mdf_app/features/grades/domain/repositories/grade_repository.dart';
import 'package:mdf_app/core/network/network_info.dart';
import 'package:mdf_app/core/storage/offline_queue.dart';

// ─────────────────────────────────────────────
// Mock classes — reusable across test files
// ─────────────────────────────────────────────

class MockAuthRepository extends Mock implements AuthRepository {}

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockCheckAuthUseCase extends Mock implements CheckAuthUseCase {}

class MockCoursesRepository extends Mock implements CoursesRepository {}

class MockGetEnrolledCoursesUseCase extends Mock
    implements GetEnrolledCoursesUseCase {}

class MockSearchCoursesUseCase extends Mock implements SearchCoursesUseCase {}

class MockGradeRepository extends Mock implements GradeRepository {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockOfflineQueue extends Mock implements OfflineQueue {}

// ─────────────────────────────────────────────
// Test Fixtures — consistent data across tests
// ─────────────────────────────────────────────

class TestFixtures {
  TestFixtures._();

  // ── Users ──
  static const tUser = User(
    id: 1,
    username: 'student1',
    firstName: 'Ali',
    lastName: 'Ahmed',
    fullName: 'Ali Ahmed',
    email: 'ali@example.com',
    profileImageUrl: 'https://img.example.com/1.jpg',
    lang: 'ar',
    isSiteAdmin: false,
    siteId: 10,
    siteName: 'MDF Academy',
    siteUrl: 'https://moodle.example.com',
  );

  static const tAdminUser = User(
    id: 2,
    username: 'admin1',
    firstName: 'Admin',
    lastName: 'User',
    fullName: 'Admin User',
    email: 'admin@example.com',
    isSiteAdmin: true,
  );

  static const tEmptyUser = User(
    id: 99,
    username: 'empty',
    firstName: '',
    lastName: '',
    fullName: '',
    email: '',
  );

  // ── Courses ──
  static const tCourse1 = Course(
    id: 1,
    shortName: 'MATH101',
    fullName: 'Mathematics 101',
    progress: 75.0,
    categoryId: 1,
    categoryName: 'Mathematics',
    visible: true,
  );

  static const tCourse2 = Course(
    id: 2,
    shortName: 'SCI201',
    fullName: 'Science 201',
    progress: 30.0,
    categoryId: 2,
    categoryName: 'Science',
    visible: true,
  );

  static const tCourse3 = Course(
    id: 3,
    shortName: 'ENG301',
    fullName: 'English 301',
    progress: 100.0,
    completed: true,
    visible: true,
  );

  static const tCourses = [tCourse1, tCourse2, tCourse3];

  // ── Grades ──
  static const tGradeItem1 = GradeItem(
    id: 1,
    itemName: 'Quiz 1',
    itemType: 'mod',
    itemModule: 'quiz',
    courseId: 1,
    gradeRaw: 85.0,
    gradeMin: 0.0,
    gradeMax: 100.0,
    percentageFormatted: 85.0,
  );

  static const tGradeItem2 = GradeItem(
    id: 2,
    itemName: 'Assignment 1',
    itemType: 'mod',
    itemModule: 'assign',
    courseId: 1,
    gradeRaw: 92.0,
    gradeMin: 0.0,
    gradeMax: 100.0,
    percentageFormatted: 92.0,
    feedback: 'Excellent work!',
  );

  static const tGradeItems = [tGradeItem1, tGradeItem2];

  static const tCourseGrade1 = CourseGrade(
    courseId: 1,
    courseName: 'Mathematics 101',
    grade: 88.5,
    rank: 3,
  );

  static const tCourseGrade2 = CourseGrade(
    courseId: 2,
    courseName: 'Science 201',
    grade: 72.0,
    rank: 12,
  );

  static const tCourseGrades = [tCourseGrade1, tCourseGrade2];

  // ── JSON fixtures ──
  static const tMoodleSiteInfoJson = {
    'userid': 1,
    'username': 'student1',
    'firstname': 'Ali',
    'lastname': 'Ahmed',
    'fullname': 'Ali Ahmed',
    'useremail': 'ali@example.com',
    'userpictureurl': 'https://img.example.com/1.jpg',
    'lang': 'ar',
    'userissiteadmin': false,
    'siteid': 10,
    'sitename': 'MDF Academy',
    'siteurl': 'https://moodle.example.com',
  };

  static const tEnrolledCourseJson = {
    'id': 1,
    'shortname': 'MATH101',
    'fullname': 'Mathematics 101',
    'displayname': 'Mathematics 101',
    'summary': '<p>Introduction to mathematics</p>',
    'summaryformat': 1,
    'category': 1,
    'categoryname': 'Mathematics',
    'startdate': 1700000000,
    'enddate': 1730000000,
    'enrolledusercount': 45,
    'visible': 1,
    'progress': 75.0,
    'completed': false,
    'isfavourite': true,
    'lastaccess': 1709000000,
    'overviewfiles': [
      {'fileurl': 'https://img.example.com/course1.jpg'},
    ],
    'contacts': [
      {
        'id': 10,
        'fullname': 'Dr. Mohammed',
        'profileimageurl': 'https://img.example.com/teacher.jpg',
      },
    ],
  };

  static const tGradeItemJson = {
    'id': 1,
    'itemname': 'Quiz 1',
    'itemtype': 'mod',
    'itemmodule': 'quiz',
    'courseid': 1,
    'graderaw': 85.0,
    'grademin': 0.0,
    'grademax': 100.0,
    'percentageformatted': 85.0,
    'feedback': null,
  };

  static const tCourseGradeJson = {
    'courseid': 1,
    'coursename': 'Mathematics 101',
    'grade': 88.5,
    'rank': 3,
  };

  static const tWhiteLabelJson = {
    'tenant_id': 'university_a',
    'app_name': 'UniApp',
    'tagline': 'Learn More',
    'moodle_base_url': 'https://lms.university.edu',
    'moodle_service': 'university_service',
    'primary_color': '#FF5722',
    'secondary_color': '#2196F3',
    'accent_color': '#FFC107',
    'logo_url': 'https://cdn.university.edu/logo.png',
    'default_locale': 'en',
    'supported_locales': ['en', 'ar', 'fr'],
    'terms_url': 'https://university.edu/terms',
    'privacy_url': 'https://university.edu/privacy',
    'support_email': 'support@university.edu',
    'features': {
      'enable_ai': true,
      'enable_social': false,
      'enable_gamification': true,
      'enable_forums': true,
      'enable_video_meetings': false,
      'enable_downloads': true,
      'enable_search': true,
      'enable_calendar': true,
      'enable_notifications': true,
      'enable_messaging': true,
      'enable_grades': true,
      'enable_quizzes': true,
      'enable_assignments': true,
      'enable_enrollment': true,
      'enable_user_management': false,
      'enable_dark_mode': true,
    },
  };

  static const tTenantConfigJson = {
    'branding': tWhiteLabelJson,
    'moodle_url': 'https://lms.university.edu',
    'max_users': 500,
    'storage_quota_bytes': 5368709120,
    'is_license_valid': true,
    'license_expiry': '2027-01-01T00:00:00.000',
    'custom_headers': {'X-Tenant': 'university_a'},
  };
}

// ─────────────────────────────────────────────
// Widget Test Helpers
// ─────────────────────────────────────────────

/// Wraps a widget in a MaterialApp for widget testing.
Widget makeTestableWidget(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      DefaultMaterialLocalizations.delegate,
      DefaultWidgetsLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );
}

/// Wraps a widget in a MaterialApp with a specific theme.
Widget makeThemedWidget(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? ThemeData.light(useMaterial3: true),
    home: Scaffold(body: child),
  );
}
