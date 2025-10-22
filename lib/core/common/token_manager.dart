import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app_limiter/core/constants/string_constants.dart';

class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  String? _accessToken;

  late FlutterSecureStorage _secureStorage;

  TokenManager._internal() {
    _secureStorage = const FlutterSecureStorage();
  }

  static TokenManager get instance {
    return _instance;
  }

  String? get accessToken => _accessToken;
  Future<bool> refreshKeyExist() async {
    try {
      String? refreshToken = await _secureStorage.read(
        key: StringConstants.refreshTokenKey,
      );
      return refreshToken != null;
    } catch (e) {
      // handle case where refreshToken retrieving throws error.
      return false;
    }
  }

  Future<void> setTokens(
    String accessToken, {
    String? refreshToken,
    bool saveRefreshToken = false,
  }) async {
    _accessToken = accessToken;
    if (refreshToken != null && saveRefreshToken) {
      await _secureStorage.write(
        key: StringConstants.refreshTokenKey,
        value: refreshToken,
      );
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: StringConstants.refreshTokenKey);
    } catch (e) {
      // handle case where refresh token retrieving throws error
      return null;
    }
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: StringConstants.refreshTokenKey);
    _accessToken = null;
  }
}
