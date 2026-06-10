import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(business.name, style: textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Signed in as ${staff.fullName}'),
                  const SizedBox(height: 16),
                  const Text('Staff context is ready.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Service Panel'),
              subtitle: const Text('QR workflow starts in F2.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: null,
            ),
          ),
        ],
      ),
    );
  }
}
