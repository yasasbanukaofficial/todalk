import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

DateTime? _decodeJwtExpiry(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final map = jsonDecode(payload) as Map<String, dynamic>;
    final exp = map['exp'] as int?;
    if (exp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
  } catch (_) {
    return null;
  }
}

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

  final Dio _dio;
  final FlutterSecureStorage _storage;

  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;

  ApiService({required String baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        )),
        _storage = const FlutterSecureStorage();

  Future<void> init() async {
    _accessToken = await _storage.read(key: _accessTokenKey);
    _refreshToken = await _storage.read(key: _refreshTokenKey);
    _tokenExpiry = _accessToken != null ? _decodeJwtExpiry(_accessToken!) : null;
  }

  bool get hasToken => _accessToken != null;
  bool get isTokenExpired =>
      _tokenExpiry != null && _tokenExpiry!.isBefore(DateTime.now().toUtc().add(const Duration(minutes: 1)));

  Future<void> setTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _tokenExpiry = _decodeJwtExpiry(accessToken);
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body, bool auth = false}) async {
    return _request('POST', path, data: body, auth: auth);
  }

  Future<Map<String, dynamic>> get(String path,
      {bool auth = false, bool isInit = false}) async {
    return _request('GET', path, auth: auth, isInit: isInit);
  }

  Future<Map<String, dynamic>> patch(String path,
      {Map<String, dynamic>? body, bool auth = false}) async {
    return _request('PATCH', path, data: body, auth: auth);
  }

  Future<Map<String, dynamic>> delete(String path,
      {bool auth = false}) async {
    return _request('DELETE', path, auth: auth);
  }

  Future<Map<String, dynamic>> _request(String method, String path,
      {Map<String, dynamic>? data, bool auth = false, bool isInit = false}) async {
    if (auth && _accessToken != null) {
      if (isTokenExpired && _refreshToken != null) {
        await _tryRefresh();
      }
    }

    final options = Options(
      method: method,
      headers: <String, dynamic>{
        if (auth && _accessToken != null) 'Authorization': 'Bearer $_accessToken',
      },
      extra: {'_auth': auth, '_isInit': isInit},
      sendTimeout: isInit ? const Duration(seconds: 5) : const Duration(seconds: 15),
      receiveTimeout: isInit ? const Duration(seconds: 5) : const Duration(seconds: 15),
    );

    try {
      var response = await _dio.request(path, data: data, options: options);

      if (response.statusCode == 401 && _refreshToken != null && auth) {
        final refreshed = await _tryRefresh();
        if (refreshed) {
          options.headers?['Authorization'] = 'Bearer $_accessToken';
          response = await _dio.request(path, data: data, options: options);
        }
      }

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{'data': response.data};
      }

      throw ApiException(
        statusCode: response.statusCode ?? 0,
        message: _extractMessage(response.data),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ApiException(statusCode: 0, message: 'Server not reachable. Check your connection.');
      }
      if (e.response != null) {
        throw ApiException(
          statusCode: e.response!.statusCode ?? 0,
          message: _extractMessage(e.response!.data),
        );
      }
      throw ApiException(statusCode: 0, message: 'Connection failed. Check your server.');
    }
  }

  String _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ?? data.toString();
    }
    return data?.toString() ?? 'Unknown error';
  }

  Future<bool> _tryRefresh() async {
    try {
      final response = await _dio.post('/auth/refresh',
        data: {'refreshToken': _refreshToken},
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        final result = data['data'] as Map<String, dynamic>? ?? data;
        final newAccess = result['accessToken'] as String?;
        if (newAccess != null) {
          _accessToken = newAccess;
          _tokenExpiry = _decodeJwtExpiry(newAccess);
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
