import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/ui/ui.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/staff_context.dart';

class BusinessSelectScreen extends ConsumerWidget {
  const BusinessSelectScreen({super.key, required this.businesses});

  final List<StaffBusiness> businesses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Select Business',
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(
                        title: 'Choose a Business',
                        subtitle:
                            'Select the business for this staff service session.',
                      ),
                      const SizedBox(height: 12),
                      if (businesses.isEmpty)
                        const EmptyStateView(
                          icon: Icons.storefront_outlined,
                          title: 'No businesses assigned',
                          message:
                              'Ask the owner to assign this staff account to a business.',
                        )
                      else
                        ...businesses.map(
                          (business) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: AppListRow(
                              title: business.name,
                              subtitle:
                                  '${business.currencyCode} · ${business.timezone}',
                              leadingIcon: Icons.storefront_rounded,
                              onTap: () {
                                ref
                                    .read(authControllerProvider.notifier)
                                    .selectBusiness(business);
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
