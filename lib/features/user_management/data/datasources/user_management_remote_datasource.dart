import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/managed_user_model.dart';

abstract class UserManagementRemoteDataSource {
  Future<List<ManagedUserModel>> getUsers({String? search, String? role});
  Future<ManagedUserModel> getUserById(int userId);
  Future<ManagedUserModel> createUser({
    required String username,
    required String password,
    required String firstName,
    required String lastName,
    required String email,
    String? department,
    String? institution,
    String? city,
    String? country,
    String? lang,
  });
  Future<void> updateUser(Map<String, dynamic> userData);
  Future<void> deleteUser(int userId);
}

class UserManagementRemoteDataSourceImpl
    implements UserManagementRemoteDataSource {
  final MoodleApiClient apiClient;

  UserManagementRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ManagedUserModel>> getUsers({
    String? search,
    String? role,
  }) async {
    final params = <String, dynamic>{};

    // core_user_get_users accepts criteria
    int criteriaIdx = 0;
    if (search != null && search.isNotEmpty) {
      params['criteria[$criteriaIdx][key]'] = 'search';
      params['criteria[$criteriaIdx][value]'] = search;
      criteriaIdx++;
    }
    if (role != null && role.isNotEmpty) {
      // Use empty search to get all, then filter by role client-side
      // Moodle doesn't support role-based filtering in core_user_get_users directly
    }

    // If no criteria, use a wildcard search
    if (params.isEmpty) {
      params['criteria[0][key]'] = 'search';
      params['criteria[0][value]'] = '';
    }

    final response = await apiClient.call(
      MoodleApiEndpoints.getUsers,
      params: params,
    );

    if (response is Map && response.containsKey('users')) {
      final users = response['users'] as List;
      var result = users
          .map((j) => ManagedUserModel.fromJson(j as Map<String, dynamic>))
          .toList();

      // Client-side role filtering
      if (role != null && role.isNotEmpty) {
        result = result
            .where((u) => u.roles.any((r) => r.shortName == role))
            .toList();
      }

      return result;
    }
    return [];
  }

  @override
  Future<ManagedUserModel> getUserById(int userId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.getUsersByField,
      params: {'field': 'id', 'values[0]': userId},
    );

    if (response is List && response.isNotEmpty) {
      return ManagedUserModel.fromJson(response.first as Map<String, dynamic>);
    }
    throw Exception('User not found');
  }

  @override
  Future<ManagedUserModel> createUser({
    required String username,
    required String password,
    required String firstName,
    required String lastName,
    required String email,
    String? department,
    String? institution,
    String? city,
    String? country,
    String? lang,
  }) async {
    final params = <String, dynamic>{
      'users[0][username]': username,
      'users[0][password]': password,
      'users[0][firstname]': firstName,
      'users[0][lastname]': lastName,
      'users[0][email]': email,
      'users[0][auth]': 'manual',
      'users[0][createpassword]': 0,
    };
    if (department != null) params['users[0][department]'] = department;
    if (institution != null) params['users[0][institution]'] = institution;
    if (city != null) params['users[0][city]'] = city;
    if (country != null) params['users[0][country]'] = country;
    if (lang != null) params['users[0][lang]'] = lang;

    final response = await apiClient.call(
      MoodleApiEndpoints.createUsers,
      params: params,
    );

    if (response is List && response.isNotEmpty) {
      final created = response.first as Map<String, dynamic>;
      final newId = created['id'] as int;
      return getUserById(newId);
    }
    throw Exception('Failed to create user');
  }

  @override
  Future<void> updateUser(Map<String, dynamic> userData) async {
    await apiClient.call(MoodleApiEndpoints.updateUsers, params: userData);
  }

  @override
  Future<void> deleteUser(int userId) async {
    await apiClient.call(
      MoodleApiEndpoints.deleteUsers,
      params: {'userids[0]': userId},
    );
  }
}
