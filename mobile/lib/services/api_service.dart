import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _timeout = Duration(seconds: 5);

  final FlutterSecureStorage _storage;
  final String baseUrl;

  String? _accessToken;
  String? _refreshToken;

  ApiService({required this.baseUrl})
      : _storage = const FlutterSecureStorage();

  Future<void> init() async {
    _accessToken = await _storage.read(key: _accessTokenKey);
    _refreshToken = await _storage.read(key: _refreshTokenKey);
  }

  bool get hasToken => _accessToken != null;

  Future<void> setTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body, bool auth = false}) async {
    return _request('POST', path, body: body, auth: auth);
  }

  Future<Map<String, dynamic>> get(String path,
      {bool auth = false}) async {
    return _request('GET', path, auth: auth);
  }

  Future<Map<String, dynamic>> patch(String path,
      {Map<String, dynamic>? body, bool auth = false}) async {
    return _request('PATCH', path, body: body, auth: auth);
  }

  Future<Map<String, dynamic>> delete(String path,
      {bool auth = false}) async {
    return _request('DELETE', path, auth: auth);
  }

  Future<Map<String, dynamic>> _request(String method, String path,
      {Map<String, dynamic>? body, bool auth = false}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (auth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    var response = await _sendRequest(method, uri, headers, body);

    if (response.statusCode == 401 && _refreshToken != null && auth) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        headers['Authorization'] = 'Bearer $_accessToken';
        response = await _sendRequest(method, uri, headers, body);
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    String msg;
    try {
      final err = jsonDecode(response.body);
      msg = err['message'] as String? ?? response.body;
    } catch (_) {
      msg = response.body;
    }
    throw ApiException(statusCode: response.statusCode, message: msg);
  }

  Future<http.Response> _sendRequest(String method, Uri uri,
      Map<String, String> headers, Map<String, dynamic>? body) async {
    final future = switch (method) {
      'GET' => http.get(uri, headers: headers),
      'POST' => http.post(uri,
          headers: headers, body: body != null ? jsonEncode(body) : null),
      'PATCH' => http.patch(uri,
          headers: headers, body: body != null ? jsonEncode(body) : null),
      'DELETE' => http.delete(uri, headers: headers),
      _ => throw ArgumentError('Unsupported method: $method'),
    };
    return future.timeout(_timeout);
  }

  Future<bool> _tryRefresh() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final data =
            decoded['data'] as Map<String, dynamic>? ?? decoded;
        final newAccess = data['accessToken'] as String?;
        if (newAccess != null) {
          _accessToken = newAccess;
          await _storage.write(key: _accessTokenKey, value: newAccess);
          return true;
        }
      }

      await clearTokens();
      return false;
    } catch (_) {
      return false;
    }
  }
}
