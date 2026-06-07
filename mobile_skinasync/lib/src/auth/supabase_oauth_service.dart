import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_api_client.dart';
import 'auth_models.dart';

class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SKINSYNC_SUPABASE_URL',
    defaultValue: 'https://hsblapeqcvnqwapcavgu.supabase.co',
  );
  static const anonKey = String.fromEnvironment(
    'SKINSYNC_SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhzYmxhcGVxY3ZucXdhcGNhdmd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQyNTA3NDcsImV4cCI6MjA4OTgyNjc0N30.7uhxufgeVYVElwBVswMXzFVmsKe1cy5wuAM8VtyzQU4',
  );
  static const redirectUrl = String.fromEnvironment(
    'SKINSYNC_SUPABASE_REDIRECT_URL',
    defaultValue: 'com.example.mobileskinasync://login-callback',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}

Future<void> configureSupabase() async {
  if (!SupabaseConfig.isConfigured) return;

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    debug: kDebugMode,
  );
}

class SupabaseOAuthService {
  SupabaseOAuthService({AuthApiClient? apiClient})
    : _apiClient = apiClient ?? AuthApiClient();

  final AuthApiClient _apiClient;

  bool get isConfigured => SupabaseConfig.isConfigured;

  Future<ApiResponse<LoginResponse>> signInWithGoogle() async {
    if (!SupabaseConfig.isConfigured) {
      return ApiResponse<LoginResponse>.failure(
        'Thiếu cấu hình Supabase. Hãy chạy app với SKINSYNC_SUPABASE_URL và SKINSYNC_SUPABASE_ANON_KEY.',
        statusCode: 500,
      );
    }

    StreamSubscription<AuthState>? subscription;
    final completer = Completer<Session>();

    try {
      final auth = Supabase.instance.client.auth;

      subscription = auth.onAuthStateChange.listen(
        (state) {
          final session = state.session;
          if (state.event == AuthChangeEvent.signedIn &&
              session != null &&
              !completer.isCompleted) {
            completer.complete(session);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
        },
      );

      final launched = await auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: SupabaseConfig.redirectUrl,
        scopes: 'email profile',
      );

      if (!launched) {
        return ApiResponse<LoginResponse>.failure(
          'Không mở được trình duyệt để đăng nhập Google.',
        );
      }

      final session = await completer.future.timeout(
        const Duration(minutes: 3),
        onTimeout: () => throw TimeoutException(
          'Google không trả callback về app trong thời gian cho phép.',
        ),
      );

      final accessToken = session.accessToken;
      if (accessToken.isEmpty) {
        return ApiResponse<LoginResponse>.failure(
          'Không nhận được access token từ Supabase.',
          statusCode: 401,
        );
      }

      return _apiClient.loginWithGoogleToken(supabaseAccessToken: accessToken);
    } on TimeoutException catch (error) {
      return ApiResponse<LoginResponse>.failure(
        error.message ?? 'Đăng nhập Google quá thời gian chờ.',
      );
    } on AuthException catch (error) {
      return ApiResponse<LoginResponse>.failure(error.message);
    } catch (_) {
      return ApiResponse<LoginResponse>.failure(
        'Không thể hoàn tất đăng nhập Google. Vui lòng thử lại.',
      );
    } finally {
      await subscription?.cancel();
    }
  }

  Future<void> signOut() async {
    if (!SupabaseConfig.isConfigured) return;

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      // SkinSync session cleanup should not be blocked by Supabase sign-out.
    }
  }
}
