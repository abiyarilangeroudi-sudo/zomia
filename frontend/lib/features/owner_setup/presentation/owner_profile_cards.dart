import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';
import '../../auth/domain/current_user.dart';
import '../domain/owner_setup_models.dart';

class OwnerProfileCard extends StatelessWidget {
  const OwnerProfileCard({
    super.key,
    required this.user,
    required this.selectedBusiness,
    required this.onOpenBusinessSettings,
    required this.onOpenAccountSettings,
  });

  final CurrentUser user;
  final OwnerBusiness? selectedBusiness;
  final VoidCallback? onOpenBusinessSettings;
  final VoidCallback onOpenAccountSettings;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Profile'),
          const SizedBox(height: 12),
          AppListRow(
            title: user.fullName,
            subtitle: user.email,
            leadingIcon: Icons.person_rounded,
          ),
          if (selectedBusiness != null) ...[
            const SizedBox(height: 12),
            AppListRow(
              title: selectedBusiness!.name,
              subtitle:
                  '${selectedBusiness!.currencyCode} · ${selectedBusiness!.status}',
              leadingIcon: Icons.storefront_rounded,
              onTap: onOpenBusinessSettings,
            ),
          ],
          const SizedBox(height: 12),
          AppListRow(
            title: 'Account Settings',
            leadingIcon: Icons.manage_accounts_rounded,
            onTap: onOpenAccountSettings,
          ),
        ],
      ),
    );
  }
}
