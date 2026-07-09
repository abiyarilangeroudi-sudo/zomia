class CustomerStatus {
  const CustomerStatus({
    required this.customerId,
    required this.activeRewardsCount,
    required this.hasEarnedFirstPoint,
    required this.hasEarnedFirstReward,
    required this.hasUsedFirstReward,
    required this.businesses,
  });

  factory CustomerStatus.fromJson(Map<String, dynamic> json) {
    return CustomerStatus(
      customerId: json['customer_id'] as String,
      activeRewardsCount: json['active_rewards_count'] as int,
      hasEarnedFirstPoint: json['has_earned_first_point'] as bool? ?? false,
      hasEarnedFirstReward: json['has_earned_first_reward'] as bool? ?? false,
      hasUsedFirstReward: json['has_used_first_reward'] as bool? ?? false,
      businesses: (json['businesses'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                CustomerBusinessStatus.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final String customerId;
  final int activeRewardsCount;
  final bool hasEarnedFirstPoint;
  final bool hasEarnedFirstReward;
  final bool hasUsedFirstReward;
  final List<CustomerBusinessStatus> businesses;
}

class CustomerBusinessStatus {
  const CustomerBusinessStatus({
    required this.businessId,
    required this.businessName,
    required this.rewards,
  });

  factory CustomerBusinessStatus.fromJson(Map<String, dynamic> json) {
    return CustomerBusinessStatus(
      businessId: json['business_id'] as String,
      businessName: json['business_name'] as String,
      rewards: (json['rewards'] as List<dynamic>? ?? [])
          .map((item) => CustomerReward.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final String businessId;
  final String businessName;
  final List<CustomerReward> rewards;
}

class CustomerCampaignProgress {
  const CustomerCampaignProgress({
    required this.businessId,
    required this.businessName,
    required this.campaignId,
    required this.campaignName,
    required this.startsAt,
    required this.endsAt,
    required this.progressPoints,
    required this.thresholdPoints,
    required this.remainingPoints,
    required this.isCompleted,
    required this.isRepeatable,
    required this.completedCycles,
    required this.currentCycleNumber,
    required this.maxCompletionsPerCustomer,
    required this.campaignTimeStatus,
    required this.progressState,
    required this.displayLabel,
    required this.badgeLabel,
    required this.badgeTone,
  });

  factory CustomerCampaignProgress.fromJson(Map<String, dynamic> json) {
    return CustomerCampaignProgress(
      businessId: json['business_id'] as String,
      businessName: json['business_name'] as String,
      campaignId: json['campaign_id'] as String,
      campaignName: json['campaign_name'] as String,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: DateTime.parse(json['ends_at'] as String),
      progressPoints: json['progress_points'] as int,
      thresholdPoints: json['threshold_points'] as int,
      remainingPoints: json['remaining_points'] as int,
      isCompleted: json['is_completed'] as bool,
      isRepeatable: json['is_repeatable'] as bool? ?? false,
      completedCycles: json['completed_cycles'] as int? ?? 0,
      currentCycleNumber: json['current_cycle_number'] as int? ?? 1,
      maxCompletionsPerCustomer: json['max_completions_per_customer'] as int?,
      campaignTimeStatus: json['campaign_time_status'] as String? ?? 'active',
      progressState: json['progress_state'] as String? ?? 'in_progress',
      displayLabel: json['display_label'] as String? ?? '',
      badgeLabel: json['badge_label'] as String? ?? 'Active',
      badgeTone: json['badge_tone'] as String? ?? 'info',
    );
  }

  final String businessId;
  final String businessName;
  final String campaignId;
  final String campaignName;
  final DateTime startsAt;
  final DateTime endsAt;
  final int progressPoints;
  final int thresholdPoints;
  final int remainingPoints;
  final bool isCompleted;
  final bool isRepeatable;
  final int completedCycles;
  final int currentCycleNumber;
  final int? maxCompletionsPerCustomer;
  final String campaignTimeStatus;
  final String progressState;
  final String displayLabel;
  final String badgeLabel;
  final String badgeTone;

  double get progressRatio {
    if (thresholdPoints <= 0) {
      return 0;
    }
    return (progressPoints / thresholdPoints).clamp(0, 1).toDouble();
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
