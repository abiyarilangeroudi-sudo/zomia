import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';
import '../domain/owner_setup_models.dart';
import 'owner_presenter.dart';
import 'owner_setup_shared_widgets.dart';

class OwnerStaffListCard extends StatelessWidget {
  const OwnerStaffListCard({
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
    return OwnerSetupCard(
      title: 'Staff',
      children: [
        OwnerStaffList(
          staffMembers: staffMembers,
          isSaving: isSaving,
          onSetStaffActive: onSetStaffActive,
        ),
      ],
    );
  }
}

class OwnerCreateStaffDialog extends StatelessWidget {
  const OwnerCreateStaffDialog({
    super.key,
    required this.emailController,
    required this.fullNameController,
    required this.passwordController,
    this.errorMessage,
    required this.isSaving,
    required this.onCreate,
  });

  final TextEditingController emailController;
  final TextEditingController fullNameController;
  final TextEditingController passwordController;
  final String? errorMessage;
  final bool isSaving;
  final Future<bool> Function() onCreate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(
        title: 'Create Staff',
        variant: AppTopBarVariant.modal,
      ),
      body: SafeArea(
        child: DashboardScroll(
          maxWidth: 640,
          child: OwnerSetupCard(
            title: 'Staff',
            children: [
              if (errorMessage != null) ...[
                InlineBanner(message: errorMessage!, tone: BannerTone.error),
                const SizedBox(height: 12),
              ],
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
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Create Staff',
                icon: Icons.person_add_alt_1_rounded,
                isLoading: isSaving,
                onPressed: isSaving
                    ? null
                    : () async {
                        final saved = await onCreate();
                        if (saved && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
              ),
            ],
          ),
        ),
      ),
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
                      label: ownerStaffStatusLabel(staffMember),
                      tone: ownerStaffStatusTone(staffMember),
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
    final presentation = ownerStaffTogglePresentation(nextActive);
    final confirmed = await showConfirmDialog(
      context: context,
      title: presentation.title,
      message: presentation.message,
      confirmLabel: presentation.confirmLabel,
      tone: presentation.tone,
    );
    if (!confirmed) {
      return;
    }
    await onSetStaffActive(staffMember, nextActive);
  }
}
