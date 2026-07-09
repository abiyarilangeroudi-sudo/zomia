class StaffServiceAttemptKeys {
  StaffServiceAttemptKeys(this._createKey);

  final String Function(String prefix) _createKey;
  final Map<String, _AttemptKey> _attempts = {};

  String keyFor({
    required String scope,
    required String signature,
    required String prefix,
  }) {
    final existing = _attempts[scope];
    if (existing != null && existing.signature == signature) {
      return existing.key;
    }
    final key = _createKey(prefix);
    _attempts[scope] = _AttemptKey(signature: signature, key: key);
    return key;
  }

  void resolve(String scope) {
    _attempts.remove(scope);
  }
}

class _AttemptKey {
  const _AttemptKey({required this.signature, required this.key});

  final String signature;
  final String key;
}
