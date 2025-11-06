import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app_limiter/core/common/token_manager.dart';

class Fetcher {
  static const String baseUrl =
      "https://uas-mobile.achmichael.my.id/api"; // ganti sesuai backend kamu

  static Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.get(url, headers: _defaultHeaders(headers));
    return _handleResponse(response);
  }

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.post(
      url,
      headers: _defaultHeaders(headers),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.put(
      url,
      headers: _defaultHeaders(headers),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.delete(url, headers: _defaultHeaders(headers));
    return _handleResponse(response);
  }

  static Map<String, String> _defaultHeaders(Map<String, String>? custom) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    // Add Authorization header if token exists
    final token = TokenManager.instance.accessToken;
    print('access token in fetcher: $token');
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    // Merge custom headers (will override default headers if same key exists)
    if (custom != null) {
      headers.addAll(custom);
    }
    
    return headers;
  }

  static dynamic _handleResponse(http.Response response) {
    final status = response.statusCode;
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (status >= 200 && status < 300) {
      return body;
    } else {
      throw body['message'];
    }
  }
}
