import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/user.dart';

class ApiClient {
  static final Dio _dio = Dio();

  static Dio get instance {
    _dio.options.baseUrl = AppConfig.baseUrl;
    _dio.options.connectTimeout = AppConfig.connectTimeout;
    _dio.options.receiveTimeout = AppConfig.receiveTimeout;

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add auth token if available
          // TODO: Get token from AuthProvider
          handler.next(options);
        },
        onError: (error, handler) {
          // Handle common errors
          handler.next(error);
        },
      ),
    );

    return _dio;
  }
}

class AuthService {
  final Dio _dio = ApiClient.instance;

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        return AuthResponse.fromMap(response.data);
      } else {
        throw Exception('Login failed');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid credentials');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Invalid input');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<AuthResponse> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );

      if (response.statusCode == 201) {
        return AuthResponse.fromMap(response.data);
      } else {
        throw Exception('Registration failed');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('User already exists');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Invalid input');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
