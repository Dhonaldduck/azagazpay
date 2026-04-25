// lib/services/api_client.dart
import 'dart:async' as async;
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/app_constants.dart';
import '../utils/app_exceptions.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final _storage = TokenStorage.instance;

  // ── Base headers ───────────────────────────────────────────────
  Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth) {
      final token = await _storage.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // ── Request helper dengan auto refresh token ──────────────────
  Future<Map<String, dynamic>> _request(
    Future<http.Response> Function(Map<String, String> headers) requestFn, {
    bool withAuth = true,
    bool retry = true,
  }) async {
    try {
      final headers = await _headers(withAuth: withAuth);
      var response = await requestFn(headers)
          .timeout(AppConstants.receiveTimeout);

      // Token expired → coba refresh sekali
      if (response.statusCode == 401 && retry && withAuth) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final newHeaders = await _headers(withAuth: true);
          response = await requestFn(newHeaders)
              .timeout(AppConstants.receiveTimeout);
        } else {
          throw const AuthException();
        }
      }

      return _parseResponse(response);
    } on SocketException {
      throw const NetworkException('Tidak ada koneksi ke server');
    } on HttpException {
      throw const NetworkException('Terjadi kesalahan jaringan');
    } on async.TimeoutException {
      throw const NetworkException('Request timeout — server terlalu lama merespons');
    }
  }

  // ── Parse response JSON ────────────────────────────────────────
  Map<String, dynamic> _parseResponse(http.Response response) {
    late Map<String, dynamic> body;
    try {
      body = json.decode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        message: 'Response server tidak valid',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw ApiException(
      message: body['message'] as String? ?? 'Terjadi kesalahan',
      statusCode: response.statusCode,
      errors: body['errors'] as List<dynamic>?,
    );
  }

  // ── Refresh token ──────────────────────────────────────────────
  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.refreshEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': refreshToken}),
      ).timeout(AppConstants.connectTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newToken = data['data']['accessToken'] as String;
        await _storage.saveAccessToken(newToken);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Public HTTP methods ────────────────────────────────────────

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    bool withAuth = true,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$path')
        .replace(queryParameters: queryParams);
    return _request((h) => http.get(uri, headers: h), withAuth: withAuth);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    return _request(
      (h) => http.post(uri, headers: h, body: json.encode(body)),
      withAuth: withAuth,
    );
  }

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    return _request(
      (h) => http.put(uri, headers: h, body: json.encode(body)),
      withAuth: withAuth,
    );
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    bool withAuth = true,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    return _request(
      (h) => http.delete(uri, headers: h),
      withAuth: withAuth,
    );
  }
}
