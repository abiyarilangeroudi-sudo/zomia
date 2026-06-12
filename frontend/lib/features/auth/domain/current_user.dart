class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
  });

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
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

  bool get isStaff => role == 'staff';
  bool get isCustomer => role == 'customer';
}
