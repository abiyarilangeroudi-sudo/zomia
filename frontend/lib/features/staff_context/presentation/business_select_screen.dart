import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../domain/staff_context.dart';

class BusinessSelectScreen extends ConsumerWidget {
  const BusinessSelectScreen({super.key, required this.businesses});

  final List<StaffBusiness> businesses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Business'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: businesses.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final business = businesses[index];
          return Card(
            child: ListTile(
              title: Text(business.name),
              subtitle: Text('${business.currencyCode} • ${business.timezone}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ref
                    .read(authControllerProvider.notifier)
                    .selectBusiness(business);
              },
            ),
          );
        },
      ),
    );
  }
}
