class OwnerBusiness {
  const OwnerBusiness({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.legalName,
    required this.slug,
    required this.category,
    required this.publicEmail,
    required this.publicPhone,
    required this.websiteUrl,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.region,
    required this.postalCode,
    required this.countryCode,
    required this.timezone,
    required this.status,
    required this.currencyCode,
  });

  factory OwnerBusiness.fromJson(Map<String, dynamic> json) {
    return OwnerBusiness(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      legalName: json['legal_name'] as String?,
      slug: json['slug'] as String,
      category: json['category'] as String?,
      publicEmail: json['public_email'] as String?,
      publicPhone: json['public_phone'] as String?,
      websiteUrl: json['website_url'] as String?,
      addressLine1: json['address_line1'] as String?,
      addressLine2: json['address_line2'] as String?,
      city: json['city'] as String?,
      region: json['region'] as String?,
      postalCode: json['postal_code'] as String?,
      countryCode: json['country_code'] as String,
      timezone: json['timezone'] as String,
      status: json['status'] as String,
      currencyCode: json['currency_code'] as String,
    );
  }

  final String id;
  final String ownerId;
  final String name;
  final String? legalName;
  final String slug;
  final String? category;
  final String? publicEmail;
  final String? publicPhone;
  final String? websiteUrl;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? region;
  final String? postalCode;
  final String countryCode;
  final String timezone;
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
    required this.staffMemberId,
    required this.invitationId,
    required this.email,
    required this.fullName,
    required this.status,
    required this.isActive,
  });

  factory OwnerStaffMember.fromJson(Map<String, dynamic> json) {
    return OwnerStaffMember(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      userId: json['user_id'] as String?,
      staffMemberId: json['staff_member_id'] as String?,
      invitationId: json['invitation_id'] as String?,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      status: json['status'] as String,
      isActive: json['is_active'] as bool,
    );
  }

  final String id;
  final String businessId;
  final String? userId;
  final String? staffMemberId;
  final String? invitationId;
  final String email;
  final String? fullName;
  final String status;
  final bool isActive;
  bool get isPending => status == 'pending';
}

class OwnerMission {
  const OwnerMission({
    required this.id,
    required this.name,
    required this.missionType,
    required this.pointValue,
    required this.isActive,
    required this.canEdit,
    required this.canDelete,
    required this.canArchive,
  });

  factory OwnerMission.fromJson(Map<String, dynamic> json) {
    return OwnerMission(
      id: json['id'] as String,
      name: json['name'] as String,
      missionType: json['mission_type'] as String,
      pointValue: json['point_value'] as int,
      isActive: json['is_active'] as bool,
      canEdit: json['can_edit'] as bool? ?? true,
      canDelete: json['can_delete'] as bool? ?? true,
      canArchive: json['can_archive'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final String missionType;
  final int pointValue;
  final bool isActive;
  final bool canEdit;
  final bool canDelete;
  final bool canArchive;
}

class OwnerCampaign {
  const OwnerCampaign({
    required this.id,
    required this.rewardTemplateId,
    required this.name,
    required this.thresholdPoints,
    required this.isRepeatable,
    required this.maxCompletionsPerCustomer,
    required this.status,
    required this.startsAt,
    required this.endsAt,
    required this.timeStatus,
    required this.displayStatus,
    required this.badgeTone,
    required this.dateRangeLabel,
  });

  factory OwnerCampaign.fromJson(Map<String, dynamic> json) {
    return OwnerCampaign(
      id: json['id'] as String,
      rewardTemplateId: json['reward_template_id'] as String,
      name: json['name'] as String,
      thresholdPoints: json['threshold_points'] as int,
      isRepeatable: json['is_repeatable'] as bool? ?? false,
      maxCompletionsPerCustomer: json['max_completions_per_customer'] as int?,
      status: json['status'] as String,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: DateTime.parse(json['ends_at'] as String),
      timeStatus: json['time_status'] as String? ?? 'active',
      displayStatus:
          json['display_status'] as String? ?? (json['status'] as String),
      badgeTone: json['badge_tone'] as String? ?? 'info',
      dateRangeLabel:
          json['date_range_label'] as String? ??
          _formatDateRange(
            DateTime.parse(json['starts_at'] as String),
            DateTime.parse(json['ends_at'] as String),
          ),
    );
  }

  final String id;
  final String rewardTemplateId;
  final String name;
  final int thresholdPoints;
  final bool isRepeatable;
  final int? maxCompletionsPerCustomer;
  final String status;
  final DateTime startsAt;
  final DateTime endsAt;
  final String timeStatus;
  final String displayStatus;
  final String badgeTone;
  final String dateRangeLabel;

  static String _formatDateRange(DateTime startsAt, DateTime endsAt) {
    String format(DateTime value) {
      final year = value.year.toString().padLeft(4, '0');
      final month = value.month.toString().padLeft(2, '0');
      final day = value.day.toString().padLeft(2, '0');
      return '$year-$month-$day';
    }

    return '${format(startsAt)} - ${format(endsAt)}';
  }
}

class OwnerRewardTemplate {
  const OwnerRewardTemplate({
    required this.id,
    required this.name,
    required this.rewardType,
    required this.giftName,
    required this.validDays,
    required this.isActive,
    required this.canEdit,
    required this.canDelete,
    required this.canArchive,
  });

  factory OwnerRewardTemplate.fromJson(Map<String, dynamic> json) {
    return OwnerRewardTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      rewardType: json['reward_type'] as String,
      giftName: json['gift_name'] as String?,
      validDays: json['valid_days'] as int,
      isActive: json['is_active'] as bool,
      canEdit: json['can_edit'] as bool? ?? true,
      canDelete: json['can_delete'] as bool? ?? true,
      canArchive: json['can_archive'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final String rewardType;
  final String? giftName;
  final int validDays;
  final bool isActive;
  final bool canEdit;
  final bool canDelete;
  final bool canArchive;
}

class OwnerActivity {
  const OwnerActivity({
    required this.actionId,
    required this.businessId,
    required this.actionType,
    required this.staffName,
    required this.staffEmail,
    required this.customerName,
    required this.customerEmail,
    required this.pointsGranted,
    required this.summary,
    required this.createdAt,
  });

  factory OwnerActivity.fromJson(Map<String, dynamic> json) {
    return OwnerActivity(
      actionId: json['action_id'] as String,
      businessId: json['business_id'] as String,
      actionType: json['action_type'] as String,
      staffName: json['staff_name'] as String,
      staffEmail: json['staff_email'] as String,
      customerName: json['customer_name'] as String,
      customerEmail: json['customer_email'] as String?,
      pointsGranted: json['points_granted'] as int,
      summary: json['summary'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String actionId;
  final String businessId;
  final String actionType;
  final String staffName;
  final String staffEmail;
  final String customerName;
  final String? customerEmail;
  final int pointsGranted;
  final String summary;
  final DateTime createdAt;
}
