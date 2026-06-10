class StaffContext {
  const StaffContext({required this.staff, required this.businesses});

  factory StaffContext.fromJson(Map<String, dynamic> json) {
    return StaffContext(
      staff: StaffUser.fromJson(json['staff'] as Map<String, dynamic>),
      businesses: (json['businesses'] as List<dynamic>)
          .map((item) => StaffBusiness.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final StaffUser staff;
  final List<StaffBusiness> businesses;
}

class StaffUser {
  const StaffUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
  });

  factory StaffUser.fromJson(Map<String, dynamic> json) {
    return StaffUser(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
    );
  }

  final String id;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;
}

class StaffBusiness {
  const StaffBusiness({
    required this.id,
    required this.name,
    required this.slug,
    required this.status,
    required this.timezone,
    required this.currencyCode,
    required this.staffMembershipId,
  });

  factory StaffBusiness.fromJson(Map<String, dynamic> json) {
    return StaffBusiness(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      status: json['status'] as String,
      timezone: json['timezone'] as String,
      currencyCode: json['currency_code'] as String,
      staffMembershipId: json['staff_membership_id'] as String,
    );
  }

  final String id;
  final String name;
  final String slug;
  final String status;
  final String timezone;
  final String currencyCode;
  final String staffMembershipId;
}
