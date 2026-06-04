class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    this.content,
  });

  final bool success;
  final int statusCode;
  final String message;
  final T? content;

  factory ApiResponse.fromJson(
    dynamic json,
    T Function(dynamic json) contentParser, {
    required int fallbackStatusCode,
  }) {
    if (json is Map<String, dynamic>) {
      final hasEnvelope =
          json.containsKey('success') || json.containsKey('content');

      if (hasEnvelope) {
        final content = json['content'];
        return ApiResponse<T>(
          success: json['success'] == true,
          statusCode: _asInt(json['statusCode']) ?? fallbackStatusCode,
          message: json['message']?.toString() ?? '',
          content: content == null ? null : contentParser(content),
        );
      }
    }

    return ApiResponse<T>(
      success: fallbackStatusCode >= 200 && fallbackStatusCode < 300,
      statusCode: fallbackStatusCode,
      message: fallbackStatusCode >= 200 && fallbackStatusCode < 300
          ? 'Success'
          : 'Request failed',
      content: fallbackStatusCode >= 200 && fallbackStatusCode < 300
          ? contentParser(json)
          : null,
    );
  }

  factory ApiResponse.failure(String message, {int statusCode = 500}) {
    return ApiResponse<T>(
      success: false,
      statusCode: statusCode,
      message: message,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String status;
  final String? avatarUrl;

  factory AuthUser.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return AuthUser(
      id: map['id']?.toString() ?? '',
      fullName: map['fullName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      role: map['role']?.toString() ?? 'user',
      status: map['status']?.toString() ?? '',
      avatarUrl: map['avatarUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'avatarUrl': avatarUrl,
    };
  }

  String get displayName {
    final trimmed = fullName.trim();
    return trimmed.isEmpty ? email : trimmed;
  }

  String get initials {
    final parts = displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'S';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class LoginResponse {
  const LoginResponse({
    required this.tokenType,
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAtUtc,
    required this.refreshTokenExpiresAtUtc,
    required this.user,
  });

  final String tokenType;
  final String accessToken;
  final String refreshToken;
  final DateTime? accessTokenExpiresAtUtc;
  final DateTime? refreshTokenExpiresAtUtc;
  final AuthUser user;

  factory LoginResponse.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return LoginResponse(
      tokenType: map['tokenType']?.toString() ?? 'Bearer',
      accessToken: map['accessToken']?.toString() ?? '',
      refreshToken: map['refreshToken']?.toString() ?? '',
      accessTokenExpiresAtUtc: DateTime.tryParse(
        map['accessTokenExpiresAtUtc']?.toString() ?? '',
      ),
      refreshTokenExpiresAtUtc: DateTime.tryParse(
        map['refreshTokenExpiresAtUtc']?.toString() ?? '',
      ),
      user: AuthUser.fromJson(map['user']),
    );
  }
}
