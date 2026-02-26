import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../auth/data/models/user_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserModel> getUserProfile(int userId);
  Future<void> updateProfile(Map<String, dynamic> userData);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final MoodleApiClient apiClient;

  ProfileRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UserModel> getUserProfile(int userId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.getUsersByField,
      params: {'field': 'id', 'values[0]': userId},
    );

    if (response is List && response.isNotEmpty) {
      return UserModel.fromUserData(response.first as Map<String, dynamic>);
    }
    throw Exception('User not found');
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> userData) async {
    await apiClient.call(
      MoodleApiEndpoints.updateUsers,
      params: {
        'users[0][id]': userData['id'],
        if (userData['firstname'] != null)
          'users[0][firstname]': userData['firstname'],
        if (userData['lastname'] != null)
          'users[0][lastname]': userData['lastname'],
        if (userData['email'] != null) 'users[0][email]': userData['email'],
        if (userData['city'] != null) 'users[0][city]': userData['city'],
        if (userData['country'] != null)
          'users[0][country]': userData['country'],
        if (userData['description'] != null)
          'users[0][description]': userData['description'],
      },
    );
  }
}
