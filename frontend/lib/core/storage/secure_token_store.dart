import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureTokenStoreProvider = Provider<TokenStore>((ref) {
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
