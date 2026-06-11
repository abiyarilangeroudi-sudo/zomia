import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../staff_service/presentation/staff_service_panel.dart';
import '../domain/staff_context.dart';

class StaffHomeScreen extends ConsumerWidget {
  const StaffHomeScreen({
    super.key,
    required this.staff,
    required this.business,
  });

  final StaffUser staff;
  final StaffBusiness business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Service'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(business.name, style: textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Signed in as ${staff.fullName}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          StaffServicePanel(business: business),
        ],
      ),
    );
  }
}
