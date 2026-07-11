import 'package:flutter/foundation.dart';

class AppConfig {
  static const _envApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    if (_envApiBaseUrl.isNotEmpty) {
      return _envApiBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:5199';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://skinsync.somee.com';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://localhost:5199';
    }
  }

  static const authCallbackScheme = 'skinsync';
  static const authCallbackHost = 'auth';
  static const authCallbackUrl = '$authCallbackScheme://$authCallbackHost';
}
