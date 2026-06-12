import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/tenant.dart';
import '../models/user.dart';

class TenantService {
  final Dio _dio;

  TenantService() : _dio = _buildDio();

  static Dio _buildDio() {
    final dio = Dio();
    dio.options.baseUrl = AppConfig.baseUrl;
    dio.options.connectTimeout = AppConfig.connectTimeout;
    dio.options.receiveTimeout = AppConfig.receiveTimeout;
    return dio;
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.authTokenKey);
  }

  Future<Options> _authOptions() async {
    final token = await _getToken();
    return Options(
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
  }

  Future<List<Tenant>> listTenants() async {
    try {
      final response = await _dio.get(
        '/tenants',
        options: await _authOptions(),
      );
      final List<dynamic> data = response.data;
      return data.map((e) => Tenant.fromMap(e)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<AssignTenantResponse> assignTenant(AssignTenantRequest request) async {
    try {
      final response = await _dio.post(
        '/tenants/assign',
        data: request.toMap(),
        options: await _authOptions(),
      );
      return AssignTenantResponse.fromMap(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<BillingSummary> getBillingSummary() async {
    try {
      final response = await _dio.get(
        '/billing/summary',
        options: await _authOptions(),
      );
      return BillingSummary.fromMap(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response?.statusCode == 401) return Exception('Unauthorized');
    if (e.response?.statusCode == 403) return Exception('Permission denied');
    if (e.response?.statusCode == 404) return Exception('Not found');
    return Exception('Network error: ${e.message}');
  }
}

class InviteService {
  final Dio _dio;

  InviteService() : _dio = _buildDio();

  static Dio _buildDio() {
    final dio = Dio();
    dio.options.baseUrl = AppConfig.baseUrl;
    dio.options.connectTimeout = AppConfig.connectTimeout;
    dio.options.receiveTimeout = AppConfig.receiveTimeout;
    return dio;
  }

  /// Accepts an invite via magic-link token and sets password.
  /// Returns auth token and user on success.
  Future<({String token, User user})> acceptInvite({
    required String inviteToken,
    required String password,
    String? name,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/invites/accept',
        data: {
          'token': inviteToken,
          'password': password,
          if (name != null) 'name': name,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return (
        token: data['token'] as String,
        user: User.fromMap(data['user'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) throw Exception('Invite not found');
      if (e.response?.statusCode == 409) {
        final msg = e.response?.data?['error'] ?? 'Invite is no longer valid';
        throw Exception(msg);
      }
      throw Exception('Network error: ${e.message}');
    }
  }
}
