import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../platform/platform_storage.dart';
import '../config/tenant_resolver.dart';

/// GraphQL client that wraps Dio for sending queries and mutations
/// to a GraphQL API Gateway.
///
/// This client can be configured to point at a standalone GraphQL
/// gateway that proxies Moodle REST calls, or directly at a
/// Moodle-compatible GraphQL endpoint.
class GraphQLClient {
  late final Dio _dio;
  final PlatformStorage _storage;
  String? _endpoint;

  GraphQLClient({required PlatformStorage storage}) : _storage = storage {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(_AuthInterceptor(_storage));
  }

  /// Set the GraphQL endpoint URL.
  Future<void> setEndpoint(String url) async {
    _endpoint = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    await _storage.write(key: _kEndpointKey, value: _endpoint!);
  }

  /// Get the current endpoint.
  Future<String?> getEndpoint() async {
    _endpoint ??= await _storage.read(key: _kEndpointKey);
    // Default: tenant's Moodle URL + /graphql
    if (_endpoint == null) {
      final tenantUrl = TenantManager.current.moodleBaseUrl;
      if (tenantUrl.isNotEmpty) {
        _endpoint = '$tenantUrl/local/graphql/api.php';
      }
    }
    return _endpoint;
  }

  /// Execute a GraphQL query.
  Future<GraphQLResponse> query(
    String query, {
    Map<String, dynamic>? variables,
    String? operationName,
  }) async {
    return _execute(query, variables: variables, operationName: operationName);
  }

  /// Execute a GraphQL mutation.
  Future<GraphQLResponse> mutate(
    String mutation, {
    Map<String, dynamic>? variables,
    String? operationName,
  }) async {
    return _execute(
      mutation,
      variables: variables,
      operationName: operationName,
    );
  }

  /// Internal executor.
  Future<GraphQLResponse> _execute(
    String document, {
    Map<String, dynamic>? variables,
    String? operationName,
  }) async {
    final endpoint = await getEndpoint();
    if (endpoint == null || endpoint.isEmpty) {
      return GraphQLResponse.error('GraphQL endpoint not configured');
    }

    final body = <String, dynamic>{
      'query': document,
      'variables': ?variables,
      'operationName': ?operationName,
    };

    try {
      final response = await _dio.post(endpoint, data: body);
      final data = response.data as Map<String, dynamic>;

      if (data.containsKey('errors')) {
        final errors = (data['errors'] as List)
            .map((e) => GraphQLError.fromJson(e as Map<String, dynamic>))
            .toList();
        return GraphQLResponse(
          data: data['data'] as Map<String, dynamic>?,
          errors: errors,
        );
      }

      return GraphQLResponse(data: data['data'] as Map<String, dynamic>?);
    } on DioException catch (e) {
      return GraphQLResponse.error(e.message ?? 'GraphQL request failed');
    }
  }

  static const _kEndpointKey = 'graphql_endpoint';
}

/// Auth interceptor — injects the Moodle token as a Bearer header.
class _AuthInterceptor extends Interceptor {
  final PlatformStorage _storage;

  _AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

// ─── Response & Error models ───

/// Represents a parsed GraphQL response.
class GraphQLResponse {
  final Map<String, dynamic>? data;
  final List<GraphQLError> errors;

  bool get hasErrors => errors.isNotEmpty;
  bool get hasData => data != null;

  GraphQLResponse({this.data, this.errors = const []});

  factory GraphQLResponse.error(String message) =>
      GraphQLResponse(errors: [GraphQLError(message: message)]);
}

/// A single GraphQL error.
class GraphQLError {
  final String message;
  final List<Map<String, dynamic>>? locations;
  final List<dynamic>? path;
  final Map<String, dynamic>? extensions;

  GraphQLError({
    required this.message,
    this.locations,
    this.path,
    this.extensions,
  });

  factory GraphQLError.fromJson(Map<String, dynamic> json) {
    return GraphQLError(
      message: json['message'] as String? ?? 'Unknown error',
      locations: (json['locations'] as List<dynamic>?)
          ?.map((l) => l as Map<String, dynamic>)
          .toList(),
      path: json['path'] as List<dynamic>?,
      extensions: json['extensions'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() => 'GraphQLError: $message';
}
