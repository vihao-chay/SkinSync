import 'package:flutter/material.dart';

import '../config/app_config.dart';

class AvatarImage extends StatelessWidget {
  const AvatarImage({
    super.key,
    required this.source,
    required this.fallback,
    this.fit = BoxFit.cover,
  });

  final String? source;
  final Widget fallback;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final value = source?.trim() ?? '';
    if (value.isEmpty) {
      return fallback;
    }

    if (_isAssetPath(value)) {
      return Image.asset(value, fit: fit, errorBuilder: (_, _, _) => fallback);
    }

    final resolvedUrl = _resolveRemoteUrl(value);
    if (resolvedUrl.isEmpty) {
      return fallback;
    }

    return Image.network(
      resolvedUrl,
      fit: fit,
      errorBuilder: (_, _, _) => fallback,
    );
  }

  bool _isAssetPath(String value) {
    return value.startsWith('assets/') || value.startsWith('asset/');
  }

  String _resolveRemoteUrl(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    if (value.startsWith('/')) {
      return '${AppConfig.apiBaseUrl}$value';
    }

    return value;
  }
}
