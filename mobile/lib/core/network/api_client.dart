import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Thin wrapper around [http] that:
/// - attaches the JWT access token to every request
/// - transparently refreshes the access token on a 401 and retries once
/// - converts non-2xx responses into [ApiException] with the backend's
///   Arabic `detail` message
/// - decodes JSON bodies into `Map`/`List` for callers
class ApiClient {
  ApiClient._internal();
  static final ApiClient instance = ApiClient._internal();

  final http.Client _http = http.Client();
  final TokenStorage _tokenStorage = TokenStorage.instance;

  Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = {"Content-Type": "application/json"};
    if (withAuth) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null) {
        headers["Authorization"] = "Bearer $token";
      }
    }
    return headers;
  }

  Future<dynamic> get(String url, {bool withAuth = true}) {
    return _send("GET", url, withAuth: withAuth);
  }

  Future<dynamic> post(String url, {Map<String, dynamic>? body, bool withAuth = true}) {
    return _send("POST", url, body: body, withAuth: withAuth);
  }

  Future<dynamic> put(String url, {Map<String, dynamic>? body, bool withAuth = true}) {
    return _send("PUT", url, body: body, withAuth: withAuth);
  }

  Future<dynamic> patch(String url, {Map<String, dynamic>? body, bool withAuth = true}) {
    return _send("PATCH", url, body: body, withAuth: withAuth);
  }

  Future<dynamic> delete(String url, {bool withAuth = true}) {
    return _send("DELETE", url, withAuth: withAuth);
  }

  Future<dynamic> _send(
    String method,
    String url, {
    Map<String, dynamic>? body,
    bool withAuth = true,
    bool isRetry = false,
  }) async {
    http.Response response;
    final headers = await _headers(withAuth: withAuth);
    final encodedBody = body != null ? jsonEncode(body) : null;

    try {
      final uri = Uri.parse(url);
      switch (method) {
        case "GET":
          response = await _http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
          break;
        case "POST":
          response = await _http.post(uri, headers: headers, body: encodedBody).timeout(const Duration(seconds: 20));
          break;
        case "PUT":
          response = await _http.put(uri, headers: headers, body: encodedBody).timeout(const Duration(seconds: 20));
          break;
        case "PATCH":
          response = await _http.patch(uri, headers: headers, body: encodedBody).timeout(const Duration(seconds: 20));
          break;
        case "DELETE":
          response = await _http.delete(uri, headers: headers).timeout(const Duration(seconds: 20));
          break;
        default:
          throw ArgumentError("Unsupported method: $method");
      }
    } on Exception {
      throw NetworkException();
    }

    // Try to refresh the token once on 401, then retry the original request.
    if (response.statusCode == 401 && withAuth && !isRetry) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        return _send(method, url, body: body, withAuth: withAuth, isRetry: true);
      }
      await _tokenStorage.clear();
      throw UnauthorizedException();
    }

    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode == 204 || response.body.isEmpty) {
      if (statusCode >= 200 && statusCode < 300) return null;
      throw ApiException(statusCode: statusCode, messageAr: "حدث خطأ غير متوقع");
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      decoded = null;
    }

    if (statusCode >= 200 && statusCode < 300) {
      return decoded;
    }

    String messageAr = "حدث خطأ غير متوقع";
    if (decoded is Map && decoded["detail"] != null) {
      final detail = decoded["detail"];
      if (detail is String) {
        messageAr = detail;
      } else if (detail is List && detail.isNotEmpty && detail.first is Map) {
        // FastAPI validation error format
        messageAr = detail.first["msg"]?.toString() ?? messageAr;
      }
    }

    throw ApiException(statusCode: statusCode, messageAr: messageAr);
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await _http.post(
        Uri.parse(ApiConstants.refresh),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refresh_token": refreshToken}),
      );

      if (response.statusCode != 200) return false;

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      await _tokenStorage.saveTokens(
        accessToken: data["access_token"] as String,
        refreshToken: data["refresh_token"] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
