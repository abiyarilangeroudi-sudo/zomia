class CustomerStatus {
  const CustomerStatus({
    required this.customerId,
    required this.totalPoints,
    required this.activeRewardsCount,
    required this.businesses,
  });

  factory CustomerStatus.fromJson(Map<String, dynamic> json) {
    return CustomerStatus(
      customerId: json['customer_id'] as String,
      totalPoints: json['total_points'] as int,
      activeRewardsCount: json['active_rewards_count'] as int,
      businesses: (json['businesses'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                CustomerBusinessStatus.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final String customerId;
  final int totalPoints;
  final int activeRewardsCount;
  final List<CustomerBusinessStatus> businesses;
}

class CustomerBusinessStatus {
  const CustomerBusinessStatus({
    required this.businessId,
    required this.businessName,
    required this.points,
    required this.rewards,
  });

  factory CustomerBusinessStatus.fromJson(Map<String, dynamic> json) {
    return CustomerBusinessStatus(
      businessId: json['business_id'] as String,
      businessName: json['business_name'] as String,
      points: json['points'] as int,
      rewards: (json['rewards'] as List<dynamic>? ?? [])
          .map((item) => CustomerReward.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final String businessId;
  final String businessName;
  final int points;
  final List<CustomerReward> rewards;

  List<CustomerReward> get activeRewards {
    return rewards.where((reward) => reward.status == 'active').toList();
  }
}

class CustomerReward {
  const CustomerReward({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardType,
    required this.status,
    required this.giftName,
    required this.discountPercent,
    required this.discountAmountMinor,
    required this.currencyCode,
    required this.expiresAt,
    required this.usedAt,
  });

  factory CustomerReward.fromJson(Map<String, dynamic> json) {
    return CustomerReward(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      rewardType: json['reward_type'] as String,
      status: json['status'] as String,
      giftName: json['gift_name'] as String?,
      discountPercent: json['discount_percent'] as int?,
      discountAmountMinor: json['discount_amount_minor'] as int?,
      currencyCode: json['currency_code'] as String?,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      usedAt: json['used_at'] == null
          ? null
          : DateTime.parse(json['used_at'] as String),
    );
  }

  final String id;
  final String title;
  final String? description;
  final String rewardType;
  final String status;
  final String? giftName;
  final int? discountPercent;
  final int? discountAmountMinor;
  final String? currencyCode;
  final DateTime expiresAt;
  final DateTime? usedAt;

  String get displayValue {
    if (giftName != null) {
      return giftName!;
    }
    if (discountPercent != null) {
      return '$discountPercent% off';
    }
    if (discountAmountMinor != null && currencyCode != null) {
      return '${(discountAmountMinor! / 100).toStringAsFixed(2)} $currencyCode';
    }
    return rewardType.replaceAll('_', ' ');
  }
}
