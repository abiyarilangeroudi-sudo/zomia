class RefreshedTokenPair {
  const RefreshedTokenPair({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;
}

class TokenRefreshCoordinator {
  Future<RefreshedTokenPair>? _inFlight;

  Future<RefreshedTokenPair> run(
    Future<RefreshedTokenPair> Function() refresh,
  ) {
    final current = _inFlight;
    if (current != null) {
      return current;
    }

    late final Future<RefreshedTokenPair> request;
    request = Future<RefreshedTokenPair>.sync(refresh).whenComplete(() {
      if (identical(_inFlight, request)) {
        _inFlight = null;
      }
    });
    _inFlight = request;
    return request;
  }
}
