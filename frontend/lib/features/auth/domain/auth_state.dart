import 'current_user.dart';
import '../../staff_context/domain/staff_context.dart';

class AuthState {
  const AuthState({
    required this.isAuthenticated,
    this.user,
    this.context,
    this.selectedBusiness,
  });

  const AuthState.unauthenticated()
    : isAuthenticated = false,
      user = null,
      context = null,
      selectedBusiness = null;

  const AuthState.authenticated({
    required CurrentUser this.user,
    this.context,
    this.selectedBusiness,
  }) : isAuthenticated = true;

  final bool isAuthenticated;
  final CurrentUser? user;
  final StaffContext? context;
  final StaffBusiness? selectedBusiness;

  bool get isStaff => user?.isStaff ?? false;
  bool get isCustomer => user?.isCustomer ?? false;

  AuthState copyWith({
    CurrentUser? user,
    StaffContext? context,
    StaffBusiness? selectedBusiness,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated,
      user: user ?? this.user,
      context: context ?? this.context,
      selectedBusiness: selectedBusiness ?? this.selectedBusiness,
    );
  }
}
