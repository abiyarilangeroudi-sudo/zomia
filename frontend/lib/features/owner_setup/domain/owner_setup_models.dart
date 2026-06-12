class OwnerBusiness {
  const OwnerBusiness({
    required this.id,
    required this.name,
    required this.slug,
    required this.status,
    required this.currencyCode,
  });

  factory OwnerBusiness.fromJson(Map<String, dynamic> json) {
    return OwnerBusiness(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      status: json['status'] as String,
      currencyCode: json['currency_code'] as String,
    );
  }

  final String id;
  final String name;
  final String slug;
  final String status;
  final String currencyCode;
}

class OwnerStaffUser {
  const OwnerStaffUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isActive,
  });

  factory OwnerStaffUser.fromJson(Map<String, dynamic> json) {
    return OwnerStaffUser(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      isActive: json['is_active'] as bool,
    );
  }

  final String id;
  final String email;
  final String fullName;
  final bool isActive;
}

class OwnerStaffMember {
  const OwnerStaffMember({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.isActive,
    required this.user,
  });

  factory OwnerStaffMember.fromJson(Map<String, dynamic> json) {
    return OwnerStaffMember(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      userId: json['user_id'] as String,
      isActive: json['is_active'] as bool,
      user: OwnerStaffUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  final String id;
  final String businessId;
  final String userId;
  final bool isActive;
  final OwnerStaffUser user;
}

class OwnerMission {
  const OwnerMission({
    required this.id,
    required this.name,
    required this.missionType,
    required this.pointValue,
    required this.isActive,
  });

  factory OwnerMission.fromJson(Map<String, dynamic> json) {
    return OwnerMission(
      id: json['id'] as String,
      name: json['name'] as String,
      missionType: json['mission_type'] as String,
      pointValue: json['point_value'] as int,
      isActive: json['is_active'] as bool,
    );
  }

  final String id;
  final String name;
  final String missionType;
  final int pointValue;
  final bool isActive;
}

class OwnerCampaign {
  const OwnerCampaign({
    required this.id,
    required this.name,
    required this.thresholdPoints,
    required this.status,
    required this.startsAt,
    required this.endsAt,
  });

  factory OwnerCampaign.fromJson(Map<String, dynamic> json) {
    return OwnerCampaign(
      id: json['id'] as String,
      name: json['name'] as String,
      thresholdPoints: json['threshold_points'] as int,
      status: json['status'] as String,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: DateTime.parse(json['ends_at'] as String),
    );
  }

  final String id;
  final String name;
  final int thresholdPoints;
  final String status;
  final DateTime startsAt;
  final DateTime endsAt;
}

class OwnerRewardTemplate {
  const OwnerRewardTemplate({
    required this.id,
    required this.name,
    required this.rewardType,
    required this.giftName,
    required this.validDays,
    required this.isActive,
  });

  factory OwnerRewardTemplate.fromJson(Map<String, dynamic> json) {
    return OwnerRewardTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      rewardType: json['reward_type'] as String,
      giftName: json['gift_name'] as String?,
      validDays: json['valid_days'] as int,
      isActive: json['is_active'] as bool,
    );
  }

  final String id;
  final String name;
  final String rewardType;
  final String? giftName;
  final int validDays;
  final bool isActive;
}
