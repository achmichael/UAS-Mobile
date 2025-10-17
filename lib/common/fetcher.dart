import 'dart:convert';
import 'package:http/http.dart' as http;

class Fetcher {
  static const String baseUrl =
      "http://192.168.1.19:5000/api"; // ganti sesuai backend kamu

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
    return {'Content-Type': 'application/json', ...?custom};
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
