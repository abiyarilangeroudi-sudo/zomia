String normalizeQrTokenInput(String input) {
  final value = input.trim();
  const prefix = 'zomia://customer/';

  if (value.startsWith(prefix)) {
    return value.substring(prefix.length).trim();
  }

  return value;
}
