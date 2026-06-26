import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'browser_storage.dart';

final secureTokenStoreProvider = Provider<TokenStore>((ref) {
  if (isBrowserStorageAvailable) {
    return BrowserTokenStore(createBrowserStorage());
  }
  return SecureTokenStore(const FlutterSecureStorage());
});

abstract class TokenStore {
  Future<String?> readAccessToken();

  Future<String?> readRefreshToken();

  Future<void> writeAccessToken(String token);

  Future<void> writeRefreshToken(String token);

  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  const SecureTokenStore(this._storage);

  static const _accessTokenKey = 'zomia_access_token';
  static const _refreshTokenKey = 'zomia_refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  @override
  Future<String?> readRefreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  @override
  Future<void> writeAccessToken(String token) {
    return _storage.write(key: _accessTokenKey, value: token);
  }

  @override
  Future<void> writeRefreshToken(String token) {
    return _storage.write(key: _refreshTokenKey, value: token);
  }

  @override
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    return Future.wait([
      writeAccessToken(accessToken),
      writeRefreshToken(refreshToken),
    ]).then((_) {});
  }

  @override
  Future<void> clear() {
    return Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]).then((_) {});
  }
}

class BrowserTokenStore implements TokenStore {
  const BrowserTokenStore(this._storage);

  static const _accessTokenKey = 'zomia_access_token';
  static const _refreshTokenKey = 'zomia_refresh_token';

  final BrowserStorage _storage;

  @override
  Future<String?> readAccessToken() async {
    return _storage.read(_accessTokenKey);
  }

  @override
  Future<String?> readRefreshToken() async {
    return _storage.read(_refreshTokenKey);
  }

  @override
  Future<void> writeAccessToken(String token) async {
    _storage.write(_accessTokenKey, token);
  }

  @override
  Future<void> writeRefreshToken(String token) async {
    _storage.write(_refreshTokenKey, token);
  }

  @override
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _storage.write(_accessTokenKey, accessToken);
    _storage.write(_refreshTokenKey, refreshToken);
  }

  @override
  Future<void> clear() async {
    _storage.delete(_accessTokenKey);
    _storage.delete(_refreshTokenKey);
  }
}
