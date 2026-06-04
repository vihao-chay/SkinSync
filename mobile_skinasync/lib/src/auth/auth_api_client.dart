import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_models.dart';

class ApiConfig {
  static const _definedBaseUrl = String.fromEnvironment(
    'SKINSYNC_API_BASE_URL',
  );

  static String get baseUrl {
    final raw = _definedBaseUrl.isNotEmpty
        ? _definedBaseUrl
        : switch (defaultTargetPlatform) {
            TargetPlatform.android => 'http://10.0.2.2:5199/api',
            TargetPlatform.iOS => 'http://localhost:5199/api',
            _ => 'http://localhost:5199/api',
          };

    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }
}

class AuthApiClient {
  AuthApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<ApiResponse<LoginResponse>> login({
    required String email,
    required String password,
  }) {
    return _post<LoginResponse>(
      '/auth/login',
      body: {'email': email, 'password': password},
      parser: LoginResponse.fromJson,
    );
  }

  Future<ApiResponse<AuthUser>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) {
    return _post<AuthUser>(
      '/auth/register',
      body: {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'password': password,
      },
      parser: AuthUser.fromJson,
    );
  }

  Future<ApiResponse<LoginResponse>> loginWithGoogleToken({
    required String supabaseAccessToken,
  }) {
    return _post<LoginResponse>(
      '/auth/login/google',
      body: {'supabaseAccessToken': supabaseAccessToken},
      parser: LoginResponse.fromJson,
    );
  }

  Future<ApiResponse<AuthUser>> me(String accessToken) async {
    return _send<AuthUser>(
      () => _client.get(
        _uri('/auth/me'),
        headers: _headers(accessToken: accessToken),
      ),
      parser: AuthUser.fromJson,
    );
  }

  Future<void> logout(String? accessToken) async {
    if (accessToken == null || accessToken.isEmpty) return;

    try {
      await _client
          .post(
            _uri('/auth/logout'),
            headers: _headers(accessToken: accessToken),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Local session cleanup is more important than blocking logout on network.
    }
  }

  Future<ApiResponse<T>> _post<T>(
    String path, {
    required Map<String, dynamic> body,
    required T Function(dynamic json) parser,
  }) {
    return _send<T>(
      () =>
          _client.post(_uri(path), headers: _headers(), body: jsonEncode(body)),
      parser: parser,
    );
  }

  Future<ApiResponse<T>> _send<T>(
    Future<http.Response> Function() request, {
    required T Function(dynamic json) parser,
  }) async {
    try {
      final response = await request().timeout(const Duration(seconds: 18));
      final body = response.body.trim();
      final decoded = body.isEmpty ? null : jsonDecode(body);

      return ApiResponse<T>.fromJson(
        decoded,
        parser,
        fallbackStatusCode: response.statusCode,
      );
    } on TimeoutException {
      return ApiResponse<T>.failure(
        'Kết nối đến server quá lâu. Vui lòng thử lại.',
      );
    } on FormatException {
      return ApiResponse<T>.failure('Không đọc được phản hồi từ server.');
    } catch (_) {
      return ApiResponse<T>.failure(
        'Không thể kết nối đến server. Kiểm tra API URL và thử lại.',
      );
    }
  }

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Map<String, String> _headers({String? accessToken}) {
    return {
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
  }
}
