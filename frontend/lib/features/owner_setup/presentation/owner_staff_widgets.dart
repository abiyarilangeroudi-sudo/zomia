import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';
import '../domain/owner_setup_models.dart';
import 'owner_presenter.dart';
import 'owner_setup_shared_widgets.dart';

class OwnerInviteStaffDialog extends StatelessWidget {
  const OwnerInviteStaffDialog({
    super.key,
    required this.emailController,
    this.errorMessage,
    this.onClearError,
    required this.isSaving,
    required this.onSend,
  });

  final TextEditingController emailController;
  final String? errorMessage;
  final VoidCallback? onClearError;
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
                InlineBanner(
                  message: errorMessage!,
                  tone: BannerTone.error,
                  onClose: onClearError,
                ),
                const SizedBox(height: 12),
              ],
              AppTextField(
                controller: emailController,
                label: 'Staff email',
                hint: 'e.g. team@business.com',
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
    required this.onInviteStaff,
    required this.onSetStaffActive,
    required this.onCancelInvitation,
  });

  final List<OwnerStaffMember> staffMembers;
  final bool isSaving;
  final VoidCallback onInviteStaff;
  final Future<void> Function(OwnerStaffMember staffMember, bool isActive)
  onSetStaffActive;
  final Future<void> Function(OwnerStaffMember staffMember) onCancelInvitation;

  @override
  Widget build(BuildContext context) {
    if (staffMembers.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EmptyStateView(
            icon: Icons.person_add_alt_1_rounded,
            title: 'Invite your first staff member',
            message:
                'Staff can scan customer QR codes and register mission actions.',
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: 'Invite staff',
            icon: Icons.person_add_alt_1_rounded,
            onPressed: isSaving ? null : onInviteStaff,
          ),
        ],
      );
    }

    final pendingInvitations = staffMembers
        .where((staffMember) => staffMember.isPending)
        .toList();
    final activeStaff = staffMembers
        .where((staffMember) => !staffMember.isPending)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pendingInvitations.isNotEmpty) ...[
          const SectionHeader(
            title: 'Pending invitations',
            subtitle: 'Waiting for staff to accept the invitation email.',
          ),
          const SizedBox(height: 8),
          ...pendingInvitations.map(
            (staffMember) => _staffRow(context, staffMember),
          ),
          if (activeStaff.isNotEmpty) const SizedBox(height: 8),
        ],
        if (activeStaff.isNotEmpty) ...[
          const SectionHeader(
            title: 'Staff members',
            subtitle: 'People who can scan customer QR codes.',
          ),
          const SizedBox(height: 8),
          ...activeStaff.map((staffMember) => _staffRow(context, staffMember)),
        ],
      ],
    );
  }

  Widget _staffRow(BuildContext context, OwnerStaffMember staffMember) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppListRow(
        title: staffMember.fullName ?? staffMember.email,
        subtitle: staffMember.isPending
            ? 'Invitation sent to ${staffMember.email}'
            : staffMember.email,
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
            if (staffMember.isPending)
              IconButton(
                tooltip: 'Cancel invitation',
                onPressed: isSaving
                    ? null
                    : () => _confirmCancelInvitation(context, staffMember),
                icon: const Icon(Icons.delete_outline_rounded),
              )
            else
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

  Future<void> _confirmCancelInvitation(
    BuildContext context,
    OwnerStaffMember staffMember,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Cancel invitation?',
      message:
          'This pending invitation will stop working. You can send a new invitation afterward.',
      confirmLabel: 'Cancel invitation',
      tone: ConfirmTone.destructive,
    );
    if (!confirmed) {
      return;
    }
    await onCancelInvitation(staffMember);
  }
}
