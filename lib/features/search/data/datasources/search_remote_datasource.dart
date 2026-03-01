import 'dart:developer' as dev;

import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../domain/entities/search_result.dart';

abstract class SearchRemoteDataSource {
  Future<List<SearchResult>> searchCourses(String query);
  Future<List<SearchResult>> searchUsers(String query);
}

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  final MoodleApiClient apiClient;

  SearchRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<SearchResult>> searchCourses(String query) async {
    try {
      final response = await apiClient.call(
        MoodleApiEndpoints.searchCourses,
        params: {'criterianame': 'search', 'criteriavalue': query},
      );

      if (response is Map && response.containsKey('courses')) {
        return (response['courses'] as List).map((j) {
          final c = j as Map<String, dynamic>;
          return SearchResult(
            id: c['id'] as int? ?? 0,
            title:
                c['fullname'] as String? ?? c['displayname'] as String? ?? '',
            subtitle: c['shortname'] as String?,
            imageUrl:
                c['overviewfiles'] is List &&
                    (c['overviewfiles'] as List).isNotEmpty
                ? (c['overviewfiles'][0]['fileurl'] as String?)
                : null,
            type: SearchResultType.course,
          );
        }).toList();
      }
    } catch (e) {
      dev.log('searchCourses error: $e', name: 'SearchDS');
    }
    return [];
  }

  @override
  Future<List<SearchResult>> searchUsers(String query) async {
    try {
      final response = await apiClient.call(
        MoodleApiEndpoints.getUsers,
        params: {
          'criteria[0][key]': 'lastname',
          'criteria[0][value]': '%$query%',
        },
      );

      List<dynamic> users = [];
      if (response is Map && response.containsKey('users')) {
        users = response['users'] as List;
      } else if (response is List) {
        users = response;
      }

      if (users.isEmpty) {
        // fallback: try firstname search
        final response2 = await apiClient.call(
          MoodleApiEndpoints.getUsers,
          params: {
            'criteria[0][key]': 'firstname',
            'criteria[0][value]': '%$query%',
          },
        );
        if (response2 is Map && response2.containsKey('users')) {
          users = response2['users'] as List;
        }
      }

      return users.map((j) {
        final u = j as Map<String, dynamic>;
        return SearchResult(
          id: u['id'] as int? ?? 0,
          title: '${u['firstname'] ?? ''} ${u['lastname'] ?? ''}'.trim(),
          subtitle: u['email'] as String?,
          imageUrl: u['profileimageurl'] as String?,
          type: SearchResultType.user,
          extra: {'username': u['username'], 'email': u['email']},
        );
      }).toList();
    } catch (e) {
      dev.log('searchUsers error: $e', name: 'SearchDS');
    }
    return [];
  }
}
