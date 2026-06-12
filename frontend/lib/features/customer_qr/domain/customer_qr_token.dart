class CustomerQrToken {
  const CustomerQrToken({
    required this.token,
    required this.qrPayload,
    required this.expiresAt,
  });

  factory CustomerQrToken.fromJson(Map<String, dynamic> json) {
    return CustomerQrToken(
      token: json['token'] as String,
      qrPayload: json['qr_payload'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  final String token;
  final String qrPayload;
  final DateTime expiresAt;
}
