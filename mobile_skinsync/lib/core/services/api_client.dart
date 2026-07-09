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

  static const _requestTimeout = Duration(seconds: 20);

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
        _extractMessage(_responseBody(response)),
        response.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> multipart(
    String path, {
    required Map<String, String> fields,
    File? file,
    String fileField = 'image',
  }) async {
    final response = await _sendWithRefresh(() async {
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
    });
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
        'Cannot connect to backend at $baseUrl. Check that the backend is running and this phone is on the same Wi-Fi.',
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
      throw ApiException(_extractMessage(body), response.statusCode);
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

  String _extractMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return (decoded['message'] ?? decoded['title'] ?? 'Request failed')
            .toString();
      }
    } catch (_) {}

    final normalized = body.trim();
    if (normalized.isEmpty) {
      return 'Request failed';
    }

    if (normalized.startsWith('<!DOCTYPE html') ||
        normalized.startsWith('<html')) {
      return 'Backend returned an HTML error page instead of JSON. Please check the backend logs.';
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
