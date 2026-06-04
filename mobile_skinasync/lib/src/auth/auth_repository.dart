import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'auth_api_client.dart';
import 'auth_models.dart';
import 'supabase_oauth_service.dart';

class AuthRepository {
  AuthRepository({AuthApiClient? apiClient, SupabaseOAuthService? oauthService})
    : _apiClient = apiClient ?? AuthApiClient(),
      _oauthService = oauthService ?? SupabaseOAuthService();

  static const _accessTokenKey = 'skinsync_access_token';
  static const _refreshTokenKey = 'skinsync_refresh_token';
  static const _userKey = 'skinsync_user';

  final AuthApiClient _apiClient;
  final SupabaseOAuthService _oauthService;

  Future<AuthUser?> restoreUser() async {
    final prefs = await SharedPreferences.getInstance();
    final rawUser = prefs.getString(_userKey);
    final accessToken = prefs.getString(_accessTokenKey);

    if (rawUser == null || accessToken == null || accessToken.isEmpty) {
      return null;
    }

    try {
      return AuthUser.fromJson(jsonDecode(rawUser));
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  Future<ApiResponse<LoginResponse>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.login(email: email, password: password);
    if (response.success && response.content != null) {
      await _saveLogin(response.content!);
    }
    return response;
  }

  Future<ApiResponse<AuthUser>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) {
    return _apiClient.register(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
    );
  }

  Future<ApiResponse<LoginResponse>> loginWithGoogle() async {
    final response = await _oauthService.signInWithGoogle();
    if (response.success && response.content != null) {
      await _saveLogin(response.content!);
    }
    return response;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey);
    await _apiClient.logout(token);
    await _oauthService.signOut();
    await clearSession();
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
  }

  Future<void> _saveLogin(LoginResponse loginResponse) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, loginResponse.accessToken);
    await prefs.setString(_refreshTokenKey, loginResponse.refreshToken);
    await prefs.setString(_userKey, jsonEncode(loginResponse.user.toJson()));
  }
}
