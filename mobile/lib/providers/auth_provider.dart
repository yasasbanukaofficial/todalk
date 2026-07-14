import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AppUser {
  final String id;
  final String email;
  final String name;

  AppUser({required this.id, required this.email, required this.name});

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
      );
}

class AuthProvider extends ChangeNotifier {
  final ApiService _api;

  AppUser? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider({required ApiService apiService}) : _api = apiService;

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasToken => _api.hasToken;

  Future<bool> tryRestoreSession() async {
    if (!_api.hasToken) return false;

    try {
      final response = await _api.get('/users/me', auth: true);
      final data = response['data'] as Map<String, dynamic>? ?? response;
      _user = AppUser.fromJson(data);
      notifyListeners();
      return true;
    } catch (_) {
      await _api.clearTokens();
      return false;
    }
  }

  Future<bool> register(
      String email, String password, String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post('/auth/register', body: {
        'email': email,
        'password': password,
        'name': name,
      });
      final data = response['data'] as Map<String, dynamic>? ?? response;
      final userData = data['user'] as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;

      await _api.setTokens(accessToken, refreshToken);
      _user = AppUser.fromJson(userData);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection failed. Check your server.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post('/auth/login', body: {
        'email': email,
        'password': password,
      });
      final data = response['data'] as Map<String, dynamic>? ?? response;
      final userData = data['user'] as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;

      await _api.setTokens(accessToken, refreshToken);
      _user = AppUser.fromJson(userData);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection failed. Check your server.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout', auth: true);
    } catch (_) {}
    await _api.clearTokens();
    _user = null;
    notifyListeners();
  }
}
