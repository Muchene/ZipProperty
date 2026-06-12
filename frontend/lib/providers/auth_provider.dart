import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && _token != null;

  AuthProvider() {
    _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(AppConfig.authTokenKey);
      final userData = prefs.getString(AppConfig.userDataKey);

      if (_token != null && userData != null) {
        _user = User.fromJson(userData);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading stored auth: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final authResponse = await _authService.login(email, password);

      _user = authResponse.user;
      _token = authResponse.token;

      // Store authentication data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConfig.authTokenKey, _token!);
      await prefs.setString(AppConfig.userDataKey, _user!.toJson());

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final authResponse = await _authService.register(name, email, password);

      _user = authResponse.user;
      _token = authResponse.token;

      // Store authentication data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConfig.authTokenKey, _token!);
      await prefs.setString(AppConfig.userDataKey, _user!.toJson());

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Called after invite acceptance — stores the returned auth token and user
  /// without going through the normal register/login flow.
  Future<void> setAuthFromInvite(String token, User user) async {
    _user = user;
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.authTokenKey, token);
    await prefs.setString(AppConfig.userDataKey, user.toJson());
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _token = null;

    // Clear stored data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.authTokenKey);
    await prefs.remove(AppConfig.userDataKey);

    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
