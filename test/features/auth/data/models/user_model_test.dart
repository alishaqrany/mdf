import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mdf_app/features/auth/data/models/user_model.dart';

void main() {
  const tJson = {
    'id': 1,
    'username': 'student1',
    'firstName': 'Ali',
    'lastName': 'Ahmed',
    'fullName': 'Ali Ahmed',
    'email': 'ali@example.com',
    'profileImageUrl': 'https://img.example.com/1.jpg',
    'lang': 'ar',
    'isSiteAdmin': false,
    'siteId': 10,
    'siteName': 'MDF Academy',
    'siteUrl': 'https://moodle.example.com',
  };

  const tSiteInfoJson = {
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

  const tUserDataJson = {
    'id': 1,
    'username': 'student1',
    'firstname': 'Ali',
    'lastname': 'Ahmed',
    'fullname': 'Ali Ahmed',
    'email': 'ali@example.com',
    'profileimageurl': 'https://img.example.com/1.jpg',
    'lang': 'ar',
  };

  group('UserModel', () {
    test('fromJson creates valid model', () {
      final user = UserModel.fromJson(tJson);
      expect(user.id, 1);
      expect(user.username, 'student1');
      expect(user.firstName, 'Ali');
      expect(user.lastName, 'Ahmed');
      expect(user.fullName, 'Ali Ahmed');
      expect(user.email, 'ali@example.com');
      expect(user.profileImageUrl, 'https://img.example.com/1.jpg');
      expect(user.lang, 'ar');
      expect(user.isSiteAdmin, false);
      expect(user.siteId, 10);
      expect(user.siteName, 'MDF Academy');
      expect(user.siteUrl, 'https://moodle.example.com');
    });

    test('toJson returns correct map', () {
      final user = UserModel.fromJson(tJson);
      final result = user.toJson();
      expect(result, tJson);
    });

    test('fromSiteInfo parses Moodle site info response', () {
      final user = UserModel.fromSiteInfo(tSiteInfoJson);
      expect(user.id, 1);
      expect(user.username, 'student1');
      expect(user.email, 'ali@example.com');
      expect(user.isSiteAdmin, false);
      expect(user.siteId, 10);
    });

    test('fromUserData parses Moodle user data response', () {
      final user = UserModel.fromUserData(tUserDataJson);
      expect(user.id, 1);
      expect(user.username, 'student1');
      expect(user.email, 'ali@example.com');
      expect(user.profileImageUrl, 'https://img.example.com/1.jpg');
    });

    test('toJsonString / fromJsonString round-trip', () {
      final user = UserModel.fromJson(tJson);
      final jsonString = user.toJsonString();
      final decoded = UserModel.fromJsonString(jsonString);
      expect(decoded.id, user.id);
      expect(decoded.username, user.username);
      expect(decoded.email, user.email);
      expect(decoded.toJson(), user.toJson());
    });

    test('fromJson handles missing optional fields', () {
      const minimal = {
        'id': 2,
        'username': 'user2',
        'firstName': '',
        'lastName': '',
        'fullName': '',
        'email': '',
      };
      final user = UserModel.fromJson(minimal);
      expect(user.id, 2);
      expect(user.profileImageUrl, isNull);
      expect(user.lang, isNull);
      expect(user.isSiteAdmin, false);
      expect(user.siteId, isNull);
    });

    test('fromSiteInfo handles admin user', () {
      final adminJson = Map<String, dynamic>.from(tSiteInfoJson);
      adminJson['userissiteadmin'] = true;
      final user = UserModel.fromSiteInfo(adminJson);
      expect(user.isSiteAdmin, true);
      expect(user.isAdmin, true);
    });
  });

  group('UserModel JSON encoding', () {
    test('jsonEncode works with toJson', () {
      final user = UserModel.fromJson(tJson);
      final encoded = jsonEncode(user.toJson());
      expect(encoded, isA<String>());
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(decoded['id'], 1);
    });
  });
}
