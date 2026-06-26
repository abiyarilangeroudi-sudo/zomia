import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/storage/browser_storage.dart';
import '../domain/customer_qr_token.dart';

final customerQrTokenStoreProvider = Provider<CustomerQrTokenStore>((ref) {
  if (isBrowserStorageAvailable) {
    return BrowserCustomerQrTokenStore(createBrowserStorage());
  }
  return SecureCustomerQrTokenStore(const FlutterSecureStorage());
});

abstract class CustomerQrTokenStore {
  Future<CustomerQrToken?> readToken();

  Future<void> writeToken(CustomerQrToken token);

  Future<void> clear();
}

class SecureCustomerQrTokenStore implements CustomerQrTokenStore {
  const SecureCustomerQrTokenStore(this._storage);

  static const _tokenKey = 'zomia_customer_qr_token';

  final FlutterSecureStorage _storage;

  @override
  Future<CustomerQrToken?> readToken() async {
    final value = await _storage.read(key: _tokenKey);
    if (value == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(value) as Map<String, dynamic>;
      return CustomerQrToken.fromJson(decoded);
    } catch (_) {
      await clear();
      return null;
    }
  }

  @override
  Future<void> writeToken(CustomerQrToken token) {
    return _storage.write(key: _tokenKey, value: jsonEncode(token.toJson()));
  }

  @override
  Future<void> clear() {
    return _storage.delete(key: _tokenKey);
  }
}

class BrowserCustomerQrTokenStore implements CustomerQrTokenStore {
  const BrowserCustomerQrTokenStore(this._storage);

  static const _tokenKey = 'zomia_customer_qr_token';

  final BrowserStorage _storage;

  @override
  Future<CustomerQrToken?> readToken() async {
    final value = _storage.read(_tokenKey);
    if (value == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(value) as Map<String, dynamic>;
      return CustomerQrToken.fromJson(decoded);
    } catch (_) {
      await clear();
      return null;
    }
  }

  @override
  Future<void> writeToken(CustomerQrToken token) async {
    _storage.write(_tokenKey, jsonEncode(token.toJson()));
  }

  @override
  Future<void> clear() async {
    _storage.delete(_tokenKey);
  }
}
