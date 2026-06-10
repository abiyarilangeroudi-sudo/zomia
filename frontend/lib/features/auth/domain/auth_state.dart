import '../../staff_context/domain/staff_context.dart';

class AuthState {
  const AuthState({
    required this.isAuthenticated,
    this.context,
    this.selectedBusiness,
  });

  const AuthState.unauthenticated()
    : isAuthenticated = false,
      context = null,
      selectedBusiness = null;

  const AuthState.authenticated({
    required StaffContext this.context,
    this.selectedBusiness,
  }) : isAuthenticated = true;

  final bool isAuthenticated;
  final StaffContext? context;
  final StaffBusiness? selectedBusiness;

  AuthState copyWith({StaffContext? context, StaffBusiness? selectedBusiness}) {
    return AuthState(
      isAuthenticated: isAuthenticated,
      context: context ?? this.context,
      selectedBusiness: selectedBusiness ?? this.selectedBusiness,
    );
  }
}
