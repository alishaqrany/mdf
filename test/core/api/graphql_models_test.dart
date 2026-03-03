import 'package:flutter_test/flutter_test.dart';
import 'package:mdf_app/core/api/graphql_client.dart';

void main() {
  // ═════════════════════════════════════════════
  //  GraphQLResponse
  // ═════════════════════════════════════════════
  group('GraphQLResponse', () {
    test('hasData is true when data is present', () {
      final response = GraphQLResponse(
        data: const {
          'user': {'id': 1},
        },
      );
      expect(response.hasData, true);
      expect(response.hasErrors, false);
    });

    test('hasData is false when data is null', () {
      final response = GraphQLResponse(data: null);
      expect(response.hasData, false);
    });

    test('hasErrors is true when errors are present', () {
      final response = GraphQLResponse(
        errors: [GraphQLError(message: 'Unauthorized')],
      );
      expect(response.hasErrors, true);
    });

    test('hasErrors is false when errors list is empty', () {
      final response = GraphQLResponse(
        data: const {'hello': 'world'},
        errors: const [],
      );
      expect(response.hasErrors, false);
    });

    test('can have both data and errors', () {
      final response = GraphQLResponse(
        data: const {'partial': 'data'},
        errors: [GraphQLError(message: 'Partial failure')],
      );
      expect(response.hasData, true);
      expect(response.hasErrors, true);
    });

    test('factory error creates response with single error', () {
      final response = GraphQLResponse.error('Something went wrong');
      expect(response.hasErrors, true);
      expect(response.hasData, false);
      expect(response.errors.length, 1);
      expect(response.errors.first.message, 'Something went wrong');
    });
  });

  // ═════════════════════════════════════════════
  //  GraphQLError
  // ═════════════════════════════════════════════
  group('GraphQLError', () {
    test('fromJson parses message', () {
      final error = GraphQLError.fromJson(const {
        'message': 'Field "name" not found',
      });
      expect(error.message, 'Field "name" not found');
      expect(error.locations, isNull);
      expect(error.path, isNull);
      expect(error.extensions, isNull);
    });

    test('fromJson parses all fields', () {
      final error = GraphQLError.fromJson(const {
        'message': 'Not authenticated',
        'locations': [
          {'line': 2, 'column': 3},
        ],
        'path': ['user', 'name'],
        'extensions': {'code': 'UNAUTHENTICATED'},
      });
      expect(error.message, 'Not authenticated');
      expect(error.locations, isNotNull);
      expect(error.locations!.length, 1);
      expect(error.path, ['user', 'name']);
      expect(error.extensions!['code'], 'UNAUTHENTICATED');
    });

    test('fromJson with null message defaults to "Unknown error"', () {
      final error = GraphQLError.fromJson(const {});
      expect(error.message, 'Unknown error');
    });

    test('toString includes message', () {
      final error = GraphQLError(message: 'Test error');
      expect(error.toString(), 'GraphQLError: Test error');
    });
  });
}
