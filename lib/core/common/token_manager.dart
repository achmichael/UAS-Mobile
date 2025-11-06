import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app_limiter/core/constants/string_constants.dart';

class TokenManager {
  static final TokenManager _instance = TokenManager._internal();

  String? _accessToken;
  bool _tokensLoaded = false;
  late FlutterSecureStorage _secureStorage;

  TokenManager._internal() {
    _secureStorage = const FlutterSecureStorage();
  }

  static TokenManager get instance => _instance;

  String? get accessToken => _accessToken;

  Future<void> loadTokens() async {
    if (_tokensLoaded) {
      return;
    }

    try {
      final storedAccess = await _secureStorage.read(
        key: StringConstants.accessTokenKey,
      );
      _accessToken = storedAccess;
    } catch (_) {
      // ignore read errors, we'll fallback to null tokens
    }

    _tokensLoaded = true;
  }

  Future<String?> getStoredAccessToken() async {
    if (_accessToken != null) {
      return _accessToken;
    }

    await loadTokens();
    return _accessToken;
  }

  Future<bool> refreshKeyExist() async {
    try {
      final refreshToken = await _secureStorage.read(
        key: StringConstants.refreshTokenKey,
      );
      return refreshToken != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> setTokens(
    String accessToken, {
    String? refreshToken,
    bool saveRefreshToken = false,
  }) async {
    _accessToken = accessToken;
    _tokensLoaded = true;

    await _secureStorage.write(
      key: StringConstants.accessTokenKey,
      value: accessToken,
    );

    if (refreshToken != null) {
      await _secureStorage.write(
        key: StringConstants.refreshTokenKey,
        value: refreshToken,
      );
    } else if (saveRefreshToken) {
      await _secureStorage.write(
        key: StringConstants.refreshTokenKey,
        value: accessToken,
      );
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: StringConstants.refreshTokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: StringConstants.refreshTokenKey);
    await _secureStorage.delete(key: StringConstants.accessTokenKey);
    _accessToken = null;
    _tokensLoaded = false;
  }
}
