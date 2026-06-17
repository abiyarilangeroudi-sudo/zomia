import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';
import '../../auth/domain/current_user.dart';
import '../domain/owner_setup_models.dart';

class OwnerProfileCard extends StatelessWidget {
  const OwnerProfileCard({
    super.key,
    required this.user,
    required this.selectedBusiness,
    required this.onSignOut,
  });

  final CurrentUser user;
  final OwnerBusiness? selectedBusiness;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Profile',
            subtitle: 'Owner context for the current setup session.',
          ),
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
            ),
          ],
          const SizedBox(height: 16),
          SecondaryButton(
            label: 'Sign out',
            icon: Icons.logout_rounded,
            onPressed: onSignOut,
          ),
        ],
      ),
    );
  }
}
