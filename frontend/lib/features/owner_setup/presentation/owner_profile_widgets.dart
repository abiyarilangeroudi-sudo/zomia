import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/brand/brand_colors.dart';
import '../../../app/ui/ui.dart';
import '../../auth/domain/current_user.dart';
import '../data/owner_setup_repository.dart';
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

class OwnerRecentActionsDialog extends ConsumerStatefulWidget {
  const OwnerRecentActionsDialog({super.key, required this.businessId});

  final String businessId;

  @override
  ConsumerState<OwnerRecentActionsDialog> createState() =>
      _OwnerRecentActionsDialogState();
}

class _OwnerRecentActionsDialogState
    extends ConsumerState<OwnerRecentActionsDialog> {
  late Future<List<OwnerActivity>> _activityFuture;

  @override
  void initState() {
    super.initState();
    _activityFuture = _loadActivity();
  }

  Future<List<OwnerActivity>> _loadActivity() {
    return ref
        .read(ownerSetupRepositoryProvider)
        .listRecentActivity(businessId: widget.businessId);
  }

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
          child: FutureBuilder<List<OwnerActivity>>(
            future: _activityFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const AppCard(
                  child: LoadingState(label: 'Loading staff actions'),
                );
              }
              if (snapshot.hasError) {
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InlineBanner(
                        message: snapshot.error.toString(),
                        tone: BannerTone.error,
                      ),
                      const SizedBox(height: 16),
                      SecondaryButton(
                        label: 'Try again',
                        icon: Icons.refresh_rounded,
                        onPressed: () {
                          setState(() => _activityFuture = _loadActivity());
                        },
                      ),
                    ],
                  ),
                );
              }
              final activities = snapshot.data ?? [];
              if (activities.isEmpty) {
                return AppCard(
                  child: EmptyStateView(
                    icon: Icons.history_rounded,
                    title: 'No staff actions yet',
                    message:
                        'Staff activity will appear here after actions are registered.',
                  ),
                );
              }
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(
                      title: 'Recent activity',
                      subtitle: 'Latest staff actions for this business.',
                    ),
                    const SizedBox(height: 12),
                    ...activities.map(
                      (activity) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppListRow(
                          title: activity.summary,
                          subtitle:
                              '${activity.customerName} · ${activity.staffName} · ${_formatActivityTime(activity.createdAt)}',
                          leadingIcon: Icons.history_rounded,
                          trailing: StatusBadge(
                            label: activity.pointsGranted > 0
                                ? '+${activity.pointsGranted} pts'
                                : activity.actionType.replaceAll('_', ' '),
                            tone: activity.pointsGranted > 0
                                ? BadgeTone.success
                                : BadgeTone.neutral,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatActivityTime(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
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
