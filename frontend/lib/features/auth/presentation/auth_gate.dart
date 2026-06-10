import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';
import 'login_screen.dart';
import '../../staff_context/presentation/business_select_screen.dart';
import '../../staff_context/presentation/staff_home_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return authState.when(
      loading: () => const _LoadingScreen(),
      error: (error, _) => LoginScreen(initialError: error.toString()),
      data: (state) {
        if (!state.isAuthenticated) {
          return const LoginScreen();
        }
        if (state.selectedBusiness == null) {
          return BusinessSelectScreen(businesses: state.context!.businesses);
        }
        return StaffHomeScreen(
          staff: state.context!.staff,
          business: state.selectedBusiness!,
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
