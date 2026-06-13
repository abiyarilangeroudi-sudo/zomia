import 'package:flutter/material.dart';

import '../../../app/brand/brand_colors.dart';
import '../../../app/ui/ui.dart';
import '../../auth/domain/current_user.dart';
import '../domain/owner_setup_models.dart';
import 'owner_setup_shared_widgets.dart';

class OwnerHeader extends StatelessWidget {
  const OwnerHeader({
    super.key,
    required this.user,
    required this.selectedBusiness,
  });

  final CurrentUser user;
  final OwnerBusiness? selectedBusiness;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Owner Setup', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Signed in as ${user.fullName}'),
          if (selectedBusiness != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                MetricPill(
                  icon: Icons.storefront_rounded,
                  label: selectedBusiness!.name,
                  color: BrandColors.teal,
                ),
                MetricPill(
                  icon: Icons.payments_rounded,
                  label: selectedBusiness!.currencyCode,
                  color: BrandColors.orange,
                ),
                MetricPill(
                  icon: Icons.verified_rounded,
                  label: selectedBusiness!.status,
                  color: BrandColors.purple,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

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

class OwnerRecentActionsDialog extends StatelessWidget {
  const OwnerRecentActionsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Staff Recent Actions',
        variant: AppTopBarVariant.modal,
      ),
      body: SafeArea(
        child: DashboardScroll(
          maxWidth: 760,
          child: AppCard(
            child: EmptyStateView(
              icon: Icons.history_rounded,
              title: 'No staff actions yet',
              message:
                  'Recent staff activity will appear here after the owner activity endpoint is available.',
              action: SecondaryButton(
                label: 'Close',
                icon: Icons.close_rounded,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OwnerBusinessPicker extends StatelessWidget {
  const OwnerBusinessPicker({
    super.key,
    required this.businesses,
    required this.selectedBusiness,
    required this.onChanged,
  });

  final List<OwnerBusiness> businesses;
  final OwnerBusiness? selectedBusiness;
  final ValueChanged<OwnerBusiness?> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Business'),
          const SizedBox(height: 12),
          SelectField<String>(
            label: 'Business',
            value: selectedBusiness?.id,
            options: businesses
                .map(
                  (business) => SelectFieldOption(
                    value: business.id,
                    label: business.name,
                  ),
                )
                .toList(),
            onChanged: (value) {
              onChanged(
                businesses
                    .where((business) => business.id == value)
                    .firstOrNull,
              );
            },
          ),
        ],
      ),
    );
  }
}

class OwnerStaffSetupCard extends StatelessWidget {
  const OwnerStaffSetupCard({
    super.key,
    required this.emailController,
    required this.fullNameController,
    required this.passwordController,
    required this.staffMembers,
    required this.isSaving,
    required this.onCreate,
    required this.onSetStaffActive,
  });

  final TextEditingController emailController;
  final TextEditingController fullNameController;
  final TextEditingController passwordController;
  final List<OwnerStaffMember> staffMembers;
  final bool isSaving;
  final VoidCallback onCreate;
  final Future<void> Function(OwnerStaffMember staffMember, bool isActive)
  onSetStaffActive;

  @override
  Widget build(BuildContext context) {
    return OwnerSetupCard(
      title: 'Staff',
      subtitle: 'Create staff access for the selected business.',
      children: [
        AppTextField(
          controller: emailController,
          label: 'Staff email',
          hint: 'staff@example.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: fullNameController,
          label: 'Staff name',
          hint: 'Staff One',
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: passwordController,
          label: 'Temporary password',
          obscureText: true,
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Create Staff',
          icon: Icons.person_add_alt_1_rounded,
          onPressed: isSaving ? null : onCreate,
          isLoading: isSaving,
        ),
        const SizedBox(height: 12),
        OwnerStaffList(
          staffMembers: staffMembers,
          isSaving: isSaving,
          onSetStaffActive: onSetStaffActive,
        ),
      ],
    );
  }
}

class OwnerStaffList extends StatelessWidget {
  const OwnerStaffList({
    super.key,
    required this.staffMembers,
    required this.isSaving,
    required this.onSetStaffActive,
  });

  final List<OwnerStaffMember> staffMembers;
  final bool isSaving;
  final Future<void> Function(OwnerStaffMember staffMember, bool isActive)
  onSetStaffActive;

  @override
  Widget build(BuildContext context) {
    if (staffMembers.isEmpty) {
      return const EmptyStateView(
        icon: Icons.person_rounded,
        title: 'No staff yet',
        message: 'Created staff users will appear here.',
      );
    }

    return Column(
      children: staffMembers
          .map(
            (staffMember) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppListRow(
                title: staffMember.user.fullName,
                subtitle: staffMember.user.email,
                leadingIcon: Icons.person_rounded,
                trailing: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(
                      label: staffMember.isActive ? 'Active' : 'Inactive',
                      tone: staffMember.isActive
                          ? BadgeTone.success
                          : BadgeTone.neutral,
                    ),
                    IconButton(
                      tooltip: staffMember.isActive
                          ? 'Deactivate staff'
                          : 'Activate staff',
                      onPressed: isSaving
                          ? null
                          : () => _confirmToggle(context, staffMember),
                      icon: Icon(
                        staffMember.isActive
                            ? Icons.person_off_rounded
                            : Icons.person_add_alt_1_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Future<void> _confirmToggle(
    BuildContext context,
    OwnerStaffMember staffMember,
  ) async {
    final nextActive = !staffMember.isActive;
    final confirmed = await showConfirmDialog(
      context: context,
      title: nextActive ? 'Activate Staff?' : 'Deactivate Staff?',
      message: nextActive
          ? 'This staff member will regain access to this business.'
          : 'This staff member will lose access to this business. History remains unchanged.',
      confirmLabel: nextActive ? 'Activate' : 'Deactivate',
      tone: nextActive ? ConfirmTone.standard : ConfirmTone.destructive,
    );
    if (!confirmed) {
      return;
    }
    await onSetStaffActive(staffMember, nextActive);
  }
}
