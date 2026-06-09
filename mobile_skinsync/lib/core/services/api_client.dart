import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/app_models.dart';

class ApiClient {
  ApiClient({required this.baseUrl});

  final String baseUrl;
  AuthSession? _session;

  void attachSession(AuthSession? session) {
    _session = session;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath').replace(
      queryParameters: query?.map((key, value) => MapEntry(key, value?.toString())),
    );
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    final response = await http.get(_uri(path, query), headers: _headers());
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> post(String path, {Object? body}) async {
    final response = await http.post(_uri(path), headers: _headers(), body: jsonEncode(body ?? const {}));
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> put(String path, {Object? body}) async {
    final response = await http.put(_uri(path), headers: _headers(), body: jsonEncode(body ?? const {}));
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> patch(String path, {Object? body}) async {
    final response = await http.patch(_uri(path), headers: _headers(), body: jsonEncode(body ?? const {}));
    return _decodeResponse(response);
  }

  Future<void> delete(String path) async {
    final response = await http.delete(_uri(path), headers: _headers());
    if (response.statusCode >= 400) {
      throw ApiException(_extractMessage(response.body), response.statusCode);
    }
  }

  Future<Map<String, dynamic>> multipart(
    String path, {
    required Map<String, String> fields,
    File? file,
    String fileField = 'image',
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    request.headers.addAll(_headers(isJson: false));
    request.fields.addAll(fields);
    if (file != null) {
      request.files.add(await http.MultipartFile.fromPath(fileField, file.path));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _decodeResponse(response);
  }

  Map<String, String> _headers({bool isJson = true}) {
    return {
      if (isJson) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_session != null) 'Authorization': 'Bearer ${_session!.accessToken}',
    };
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final body = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(body);
    if (response.statusCode >= 400) {
      throw ApiException(_extractMessage(body), response.statusCode);
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

  String _extractMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return (decoded['message'] ?? decoded['title'] ?? 'Request failed').toString();
      }
    } catch (_) {
    }
    return body;
  }
}

class ApiException implements Exception {
  ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}
