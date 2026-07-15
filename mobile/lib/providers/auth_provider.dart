import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/api_service.dart';
import 'api_providers.dart';

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

class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  late final GoogleSignIn _googleSignIn;

  @override
  AuthState build() {
    _googleSignIn = GoogleSignIn(
      serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'],
    );
    return AuthState();
  }

  ApiService get _api => ref.read(apiServiceProvider);

  Future<bool> tryRestoreSession() async {
    if (!_api.hasToken) return false;

    try {
      final response = await _api.get('/users/me', auth: true, isInit: true);
      final data = response['data'] as Map<String, dynamic>? ?? response;
      state = state.copyWith(user: AppUser.fromJson(data));
      return true;
    } catch (_) {
      await _api.clearTokens();
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, clearError: true);

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
      state = state.copyWith(user: AppUser.fromJson(userData), isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message, isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Connection failed. Check your server.', isLoading: false);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        state = state.copyWith(error: 'Failed to get Google ID token', isLoading: false);
        return false;
      }

      final response = await _api.post('/auth/google', body: {
        'idToken': idToken,
      });
      final data = response['data'] as Map<String, dynamic>? ?? response;
      final userData = data['user'] as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;

      await _api.setTokens(accessToken, refreshToken);
      state = state.copyWith(user: AppUser.fromJson(userData), isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message, isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Google sign-in failed. Make sure Google Play Services is up to date.',
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

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
      state = state.copyWith(user: AppUser.fromJson(userData), isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message, isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Connection failed. Check your server.', isLoading: false);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout', auth: true);
    } catch (_) {}
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _api.clearTokens();
    state = AuthState();
  }
}
