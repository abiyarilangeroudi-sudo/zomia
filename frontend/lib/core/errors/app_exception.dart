class AppException implements Exception {
  const AppException(this.message, {this.isAmbiguousRetry = false});

  final String message;
  final bool isAmbiguousRetry;

  @override
  String toString() => message;
}
