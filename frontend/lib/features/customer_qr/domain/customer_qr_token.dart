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

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'qr_payload': qrPayload,
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  final String token;
  final String qrPayload;
  final DateTime expiresAt;
}
