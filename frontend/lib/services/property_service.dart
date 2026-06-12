import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/property.dart';

class PropertyService {
  final Dio _dio;

  PropertyService() : _dio = _buildDio();

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

  Future<List<Property>> listProperties() async {
    try {
      final response = await _dio.get(
        '/properties',
        options: await _authOptions(),
      );
      final List<dynamic> data = response.data;
      return data.map((e) => Property.fromMap(e)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Property> createProperty(CreatePropertyRequest request) async {
    try {
      final response = await _dio.post(
        '/properties',
        data: request.toMap(),
        options: await _authOptions(),
      );
      return Property.fromMap(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<AssignAgentResponse> assignAgent(
    String propertyId,
    String email, {
    String? name,
  }) async {
    try {
      final response = await _dio.post(
        '/properties/$propertyId/agents',
        data: {'email': email, if (name != null) 'name': name},
        options: await _authOptions(),
      );
      return AssignAgentResponse.fromMap(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response?.statusCode == 401) return Exception('Unauthorized');
    if (e.response?.statusCode == 403) return Exception('Permission denied');
    if (e.response?.statusCode == 404) return Exception('Property not found');
    if (e.response?.statusCode == 409) {
      return Exception('Agent already assigned');
    }
    return Exception('Network error: ${e.message}');
  }
}
