// lib/core/network/auth_http_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// HTTP Client that automatically handles token refresh on 401 responses
class AuthHttpClient extends http.BaseClient {
  final http.Client _inner;
  final SharedPreferences _prefs;
  final String _baseUrl;
  final String _tenantId;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  bool _isRefreshing = false;

  AuthHttpClient({
    required http.Client inner,
    required SharedPreferences prefs,
    required String baseUrl,
    required String tenantId,
  })  : _inner = inner,
        _prefs = prefs,
        _baseUrl = baseUrl,
        _tenantId = tenantId;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Add auth headers
    _addAuthHeaders(request);

    // Send the request
    var response = await _inner.send(request);

    // If 401 and not already refreshing, try to refresh token
    if (response.statusCode == 401 && !_isRefreshing) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Retry the original request with new token
        final newRequest = _copyRequest(request);
        _addAuthHeaders(newRequest);
        response = await _inner.send(newRequest);
      }
    }

    return response;
  }

  void _addAuthHeaders(http.BaseRequest request) {
    request.headers['Content-Type'] = 'application/json';
    request.headers['X-Tenant-ID'] = _tenantId;

    final token = _prefs.getString(_accessTokenKey);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
  }

  http.BaseRequest _copyRequest(http.BaseRequest original) {
    if (original is http.Request) {
      final newRequest = http.Request(original.method, original.url)
        ..headers.addAll(original.headers)
        ..body = original.body;
      return newRequest;
    }
    throw UnsupportedError('Cannot copy request of type ${original.runtimeType}');
  }

  Future<bool> _refreshToken() async {
    _isRefreshing = true;
    try {
      final refreshToken = _prefs.getString(_refreshTokenKey);
      if (refreshToken == null) {
        return false;
      }

      final response = await _inner.post(
        Uri.parse('$_baseUrl/api/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'X-Tenant-ID': _tenantId,
        },
        body: json.encode({
          'refreshToken': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _prefs.setString(_accessTokenKey, data['accessToken']);
        await _prefs.setString(_refreshTokenKey, data['refreshToken']);
        return true;
      } else {
        // Refresh token is invalid - clear tokens but don't logout automatically
        // This allows the app to prompt for re-authentication
        return false;
      }
    } catch (e) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Check if user has valid tokens stored
  bool get hasTokens => _prefs.getString(_accessTokenKey) != null;

  /// Get current access token
  String? get accessToken => _prefs.getString(_accessTokenKey);

  @override
  void close() {
    _inner.close();
  }
}
