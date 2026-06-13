import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/ui/ui.dart';
import '../../customer_qr/presentation/customer_screen.dart';
import '../../owner_setup/presentation/owner_screen.dart';
import '../../staff_context/presentation/business_select_screen.dart';
import '../../staff_context/presentation/staff_home_screen.dart';
import 'auth_controller.dart';
import 'login_screen.dart';

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
        if (state.isCustomer) {
          return CustomerScreen(user: state.user!);
        }
        if (state.user!.isOwner) {
          return OwnerScreen(user: state.user!);
        }
        if (!state.isStaff) {
          return const _UnsupportedRoleScreen();
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

class _UnsupportedRoleScreen extends ConsumerWidget {
  const _UnsupportedRoleScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Zomia',
        variant: AppTopBarVariant.business,
        onMenu: () {},
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: AppCard(
              child: EmptyStateView(
                icon: Icons.manage_accounts_outlined,
                title: 'Unsupported role',
                message: 'This role is not supported in the MVP app yet.',
                action: SecondaryButton(
                  label: 'Sign out',
                  icon: Icons.logout_rounded,
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).signOut(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 420),
            child: AppCard(child: LoadingState(label: 'Loading Zomia')),
          ),
        ),
      ),
    );
  }
}
