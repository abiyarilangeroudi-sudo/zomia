class StaffServiceMission {
  const StaffServiceMission({
    required this.id,
    required this.name,
    required this.description,
    required this.missionType,
    required this.pointValue,
    required this.isActive,
  });

  factory StaffServiceMission.fromJson(Map<String, dynamic> json) {
    return StaffServiceMission(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      missionType: json['mission_type'] as String,
      pointValue: json['point_value'] as int,
      isActive: json['is_active'] as bool,
    );
  }

  final String id;
  final String name;
  final String? description;
  final String missionType;
  final int pointValue;
  final bool isActive;
}

class StaffServiceCustomer {
  const StaffServiceCustomer({
    required this.id,
    required this.fullName,
    required this.role,
    required this.isActive,
  });

  factory StaffServiceCustomer.fromJson(Map<String, dynamic> json) {
    return StaffServiceCustomer(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
    );
  }

  final String id;
  final String fullName;
  final String role;
  final bool isActive;
}

class GeneratedReward {
  const GeneratedReward({
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
  });

  factory GeneratedReward.fromJson(Map<String, dynamic> json) {
    return GeneratedReward(
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

class StaffRecentAction {
  const StaffRecentAction({
    required this.id,
    required this.actionType,
    required this.occurredAt,
    required this.createdAt,
  });

  factory StaffRecentAction.fromJson(Map<String, dynamic> json) {
    return StaffRecentAction(
      id: json['id'] as String,
      actionType: json['action_type'] as String,
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String actionType;
  final DateTime occurredAt;
  final DateTime createdAt;
}

class StaffServiceSummary {
  const StaffServiceSummary({
    required this.businessId,
    required this.customer,
    required this.points,
    required this.activeRewards,
    required this.recentActions,
  });

  factory StaffServiceSummary.fromJson(Map<String, dynamic> json) {
    return StaffServiceSummary(
      businessId: json['business_id'] as String,
      customer: StaffServiceCustomer.fromJson(
        json['customer'] as Map<String, dynamic>,
      ),
      points: json['points'] as int,
      activeRewards: (json['active_rewards'] as List<dynamic>)
          .map((item) => GeneratedReward.fromJson(item as Map<String, dynamic>))
          .toList(),
      recentActions: (json['recent_actions'] as List<dynamic>? ?? [])
          .map(
            (item) => StaffRecentAction.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final String businessId;
  final StaffServiceCustomer customer;
  final int points;
  final List<GeneratedReward> activeRewards;
  final List<StaffRecentAction> recentActions;
}

class RegisterActionResult {
  const RegisterActionResult({
    required this.pointsGranted,
    required this.idempotencyReplayed,
    required this.summary,
  });

  factory RegisterActionResult.fromJson(Map<String, dynamic> json) {
    final action = json['action'] as Map<String, dynamic>;
    return RegisterActionResult(
      pointsGranted: action['points_granted'] as int,
      idempotencyReplayed: action['idempotency_replayed'] as bool,
      summary: StaffServiceSummary.fromJson(
        json['summary'] as Map<String, dynamic>,
      ),
    );
  }

  final int pointsGranted;
  final bool idempotencyReplayed;
  final StaffServiceSummary summary;
}

class UseRewardResult {
  const UseRewardResult({
    required this.idempotencyReplayed,
    required this.summary,
  });

  factory UseRewardResult.fromJson(Map<String, dynamic> json) {
    final rewardUse = json['reward_use'] as Map<String, dynamic>;
    return UseRewardResult(
      idempotencyReplayed: rewardUse['idempotency_replayed'] as bool,
      summary: StaffServiceSummary.fromJson(
        json['summary'] as Map<String, dynamic>,
      ),
    );
  }

  final bool idempotencyReplayed;
  final StaffServiceSummary summary;
}
