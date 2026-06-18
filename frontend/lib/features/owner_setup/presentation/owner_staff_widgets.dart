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

class OwnerInviteStaffDialog extends StatelessWidget {
  const OwnerInviteStaffDialog({
    super.key,
    required this.emailController,
    this.errorMessage,
    required this.isSaving,
    required this.onSend,
  });

  final TextEditingController emailController;
  final String? errorMessage;
  final bool isSaving;
  final Future<bool> Function() onSend;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(
        title: 'Invite Staff',
        variant: AppTopBarVariant.modal,
      ),
      body: SafeArea(
        child: DashboardScroll(
          maxWidth: 640,
          child: OwnerSetupCard(
            title: 'Staff invitation',
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
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Send invitation',
                icon: Icons.mark_email_read_rounded,
                isLoading: isSaving,
                onPressed: isSaving
                    ? null
                    : () async {
                        final saved = await onSend();
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
        message: 'Staff invitations and members will appear here.',
      );
    }

    return Column(
      children: staffMembers
          .map(
            (staffMember) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppListRow(
                title: staffMember.fullName ?? staffMember.email,
                subtitle: staffMember.email,
                leadingIcon: staffMember.isPending
                    ? Icons.mark_email_unread_rounded
                    : Icons.person_rounded,
                trailing: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(
                      label: ownerStaffStatusLabel(staffMember),
                      tone: ownerStaffStatusTone(staffMember),
                    ),
                    if (!staffMember.isPending)
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
