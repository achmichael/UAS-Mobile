import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:app_limiter/core/common/token_manager.dart';
import 'package:app_limiter/core/common/fetcher.dart';

class MultipartFetcher {
  static const String baseUrl = Fetcher.baseUrl;

  /// Upload profile with multipart/form-data
  static Future<dynamic> updateProfileWithImage({
    required String name,
    required String email,
    File? profileImage,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/profile');
      final request = http.MultipartRequest('PUT', url);

      final token = TokenManager.instance.accessToken;
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['name'] = name;
      request.fields['email'] = email;

      if (profileImage != null) {
        final fileExtension = profileImage.path.split('.').last.toLowerCase();
        final mimeType = _getMimeType(fileExtension);

        final multipartFile = await http.MultipartFile.fromPath(
          'profileImage', // Field name must match backend
          profileImage.path,
          contentType: MediaType.parse(mimeType),
        );
        request.files.add(multipartFile);
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      throw 'Network error: ${e.toString()}';
    }
  }

  static String _getMimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  static dynamic _handleResponse(http.Response response) {
    final status = response.statusCode;
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (status >= 200 && status < 300) {
      return body;
    } else {
      if (body != null && body['message'] != null) {
        throw body['message'];
      } else {
        throw 'Server error: $status';
      }
    }
  }
}
