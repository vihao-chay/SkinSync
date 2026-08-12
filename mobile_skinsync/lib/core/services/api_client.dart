import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/app_models.dart';

typedef RefreshSessionHandler =
    Future<AuthSession?> Function(String refreshToken);
typedef SessionChangedHandler = Future<void> Function(AuthSession? session);

class ApiClient {
  ApiClient({required this.baseUrl});

  static const _requestTimeout = Duration(seconds: 60);

  final String baseUrl;
  AuthSession? _session;
  RefreshSessionHandler? _refreshSessionHandler;
  SessionChangedHandler? _sessionChangedHandler;
  Future<AuthSession?>? _refreshFuture;

  void attachSession(AuthSession? session) {
    _session = session;
  }

  void configureAuth({
    RefreshSessionHandler? refreshSessionHandler,
    SessionChangedHandler? sessionChangedHandler,
  }) {
    _refreshSessionHandler = refreshSessionHandler;
    _sessionChangedHandler = sessionChangedHandler;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath').replace(
      queryParameters: query?.map(
        (key, value) => MapEntry(key, value?.toString()),
      ),
    );
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _sendWithRefresh(
      () => http.get(_uri(path, query), headers: _headers()),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    Duration? timeout,
  }) async {
    final response = await _sendWithRefresh(
      () => http.post(
        _uri(path),
        headers: _headers(),
        body: jsonEncode(body ?? const {}),
      ),
      timeout: timeout,
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> postWithoutRefresh(
    String path, {
    Object? body,
  }) async {
    final response = await _sendNetworkRequest(
      () => http.post(
        _uri(path),
        headers: _headers(),
        body: jsonEncode(body ?? const {}),
      ),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> put(String path, {Object? body}) async {
    final response = await _sendWithRefresh(
      () => http.put(
        _uri(path),
        headers: _headers(),
        body: jsonEncode(body ?? const {}),
      ),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> patch(String path, {Object? body}) async {
    final response = await _sendWithRefresh(
      () => http.patch(
        _uri(path),
        headers: _headers(),
        body: jsonEncode(body ?? const {}),
      ),
    );
    return _decodeResponse(response);
  }

  Future<void> delete(String path) async {
    final response = await _sendWithRefresh(
      () => http.delete(_uri(path), headers: _headers()),
    );
    if (response.statusCode >= 400) {
      throw ApiException(
        _extractMessage(_responseBody(response), response.statusCode),
        response.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> multipart(
    String path, {
    required Map<String, String> fields,
    File? file,
    String fileField = 'image',
    Duration? timeout,
  }) async {
    final response = await _sendWithRefresh(
      () async {
        final request = http.MultipartRequest('POST', _uri(path));
        request.headers.addAll(_headers(isJson: false));
        request.fields.addAll(fields);
        if (file != null) {
          request.files.add(
            await http.MultipartFile.fromPath(fileField, file.path),
          );
        }

        final streamed = await request.send();
        return http.Response.fromStream(streamed);
      },
      timeout: timeout,
    );
    return _decodeResponse(response);
  }

  Map<String, String> _headers({bool isJson = true}) {
    return {
      if (isJson) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_session != null) 'Authorization': 'Bearer ${_session!.accessToken}',
    };
  }

  Future<http.Response> _sendWithRefresh(
    Future<http.Response> Function() send, {
    Duration? timeout,
  }) async {
    var response = await _sendNetworkRequest(send, timeout: timeout);
    if (response.statusCode != 401 ||
        _session == null ||
        _refreshSessionHandler == null) {
      return response;
    }

    final refreshed = await _refresh();
    if (refreshed == null) {
      return response;
    }

    response = await _sendNetworkRequest(send, timeout: timeout);
    return response;
  }

  Future<http.Response> _sendNetworkRequest(
    Future<http.Response> Function() send, {
    Duration? timeout,
  }) async {
    try {
      return await send().timeout(timeout ?? _requestTimeout);
    } on TimeoutException {
      throw ApiException(
        'Cannot connect to backend at $baseUrl. The server may be waking up or taking too long to respond. Please try again.',
        0,
      );
    } on SocketException {
      throw ApiException(
        'Cannot connect to backend at $baseUrl. Use your computer LAN IP, not localhost or 10.0.2.2, on a real Android phone.',
        0,
      );
    } on HandshakeException {
      throw ApiException(
        'Could not establish a secure connection to $baseUrl.',
        0,
      );
    } on http.ClientException catch (error) {
      throw ApiException(error.message, 0);
    }
  }

  Future<AuthSession?> _refresh() async {
    if (_refreshFuture != null) {
      return _refreshFuture;
    }

    final refreshToken = _session?.refreshToken;
    if (refreshToken == null ||
        refreshToken.isEmpty ||
        _refreshSessionHandler == null) {
      return null;
    }

    _refreshFuture = _refreshSessionHandler!(refreshToken);
    try {
      final refreshed = await _refreshFuture;
      _session = refreshed;
      if (_sessionChangedHandler != null) {
        await _sessionChangedHandler!(refreshed);
      }
      return refreshed;
    } finally {
      _refreshFuture = null;
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final body = _responseBody(response);
    if (response.statusCode >= 400) {
      throw ApiException(
        _extractMessage(body, response.statusCode),
        response.statusCode,
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw ApiException(
        'Backend returned an invalid response. Please check server logs.',
        response.statusCode,
      );
    }

    if (decoded is Map<String, dynamic> && decoded.containsKey('content')) {
      final content = decoded['content'];
      if (content is Map<String, dynamic>) {
        return content;
      }
      if (content is List) {
        return <String, dynamic>{'items': content};
      }
      return <String, dynamic>{'value': content};
    }

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return <String, dynamic>{'items': decoded};
  }

  String _responseBody(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return '{}';
    }
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }

  String _extractMessage(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = _findMessage(decoded);
        if (message != null && message.trim().isNotEmpty) {
          return _sanitizeServerMessage(message);
        }
      }
    } catch (_) {}

    final normalized = body.trim();
    if (normalized.isEmpty) {
      return _fallbackMessageForStatus(statusCode);
    }

    final lower = normalized.toLowerCase();
    if (lower.startsWith('<!doctype html') ||
        lower.startsWith('<html') ||
        lower.contains('<html') ||
        lower.contains('<body')) {
      return 'Backend ch\u01b0a ph\u1ee5c v\u1ee5 API \u0111\u00fang t\u1ea1i $baseUrl. Vui l\u00f2ng ki\u1ec3m tra b\u1ea3n deploy Somee.';
    }

    final sanitized = _sanitizeServerMessage(normalized);
    if (sanitized.trim().isEmpty || sanitized.trim() == '{}') {
      return _fallbackMessageForStatus(statusCode);
    }
    return sanitized;
  }

  String? _findMessage(Map<String, dynamic> decoded) {
    for (final key in const [
      'message',
      'title',
      'error_description',
      'error',
      'detail',
    ]) {
      final value = decoded[key];
      final text = _messageFromValue(value);
      if (text != null && text.trim().isNotEmpty) {
        return text;
      }
    }

    final content = decoded['content'];
    if (content is Map<String, dynamic>) {
      final text = _findMessage(content);
      if (text != null && text.trim().isNotEmpty) {
        return text;
      }
    }

    final errors = decoded['errors'];
    final errorText = _messageFromValue(errors);
    if (errorText != null && errorText.trim().isNotEmpty) {
      return errorText;
    }

    return null;
  }

  String? _messageFromValue(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    if (value is List) {
      return value
          .map(_messageFromValue)
          .whereType<String>()
          .where((item) => item.trim().isNotEmpty)
          .join('\n');
    }
    if (value is Map<String, dynamic>) {
      final nested = _findMessage(value);
      if (nested != null && nested.trim().isNotEmpty) {
        return nested;
      }
      return value.values
          .map(_messageFromValue)
          .whereType<String>()
          .where((item) => item.trim().isNotEmpty)
          .join('\n');
    }
    return value.toString();
  }

  String _fallbackMessageForStatus(int statusCode) {
    return switch (statusCode) {
      400 => 'Y\u00eau c\u1ea7u kh\u00f4ng h\u1ee3p l\u1ec7. Vui l\u00f2ng ki\u1ec3m tra l\u1ea1i th\u00f4ng tin.',
      401 => 'Phi\u00ean \u0111\u0103ng nh\u1eadp \u0111\u00e3 h\u1ebft h\u1ea1n. Vui l\u00f2ng \u0111\u0103ng nh\u1eadp l\u1ea1i.',
      403 => 'T\u00e0i kho\u1ea3n hi\u1ec7n t\u1ea1i ch\u01b0a c\u00f3 quy\u1ec1n d\u00f9ng t\u00ednh n\u0103ng n\u00e0y.',
      404 => 'Kh\u00f4ng t\u00ecm th\u1ea5y API tr\u00ean backend. Vui l\u00f2ng ki\u1ec3m tra b\u1ea3n deploy.',
      413 => '\u1ea2nh qu\u00e1 l\u1edbn. Vui l\u00f2ng ch\u1ecdn \u1ea3nh nh\u1ecf h\u01a1n.',
      500 => 'Backend \u0111ang l\u1ed7i n\u1ed9i b\u1ed9. Vui l\u00f2ng ki\u1ec3m tra log server.',
      502 || 503 => 'D\u1ecbch v\u1ee5 AI ch\u01b0a s\u1eb5n s\u00e0ng. Vui l\u00f2ng ki\u1ec3m tra OpenAI API key tr\u00ean backend.',
      _ => 'Y\u00eau c\u1ea7u th\u1ea5t b\u1ea1i (HTTP $statusCode). Vui l\u00f2ng th\u1eed l\u1ea1i.',
    };
  }

  String _sanitizeServerMessage(String message) {
    final normalized = message.trim();
    final lower = normalized.toLowerCase();

    if (lower.contains('max clients reached') ||
        lower.contains('too many clients') ||
        lower.contains('remaining connection slots') ||
        lower.contains('npgsql.postgresexception')) {
      return 'D\u1eef li\u1ec7u \u0111ang qu\u00e1 t\u1ea3i. Vui l\u00f2ng th\u1eed l\u1ea1i sau gi\u00e2y l\u00e1t.';
    }

    if (lower.contains('invalid_api_key') ||
        lower.contains('incorrect api key') ||
        lower.contains('api key provided') ||
        lower.contains('openai api key')) {
      return 'AI ch\u01b0a \u0111\u01b0\u1ee3c c\u1ea5u h\u00ecnh OpenAI API key h\u1ee3p l\u1ec7 tr\u00ean backend.';
    }

    if (lower.contains(' at npgsql.') ||
        lower.contains(' at microsoft.entityframeworkcore.') ||
        lower.contains(' at system.runtime.compilerservices.')) {
      return 'Backend is busy right now. Please try again in a moment.';
    }

    return normalized;
  }
}

class ApiException implements Exception {
  ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}
