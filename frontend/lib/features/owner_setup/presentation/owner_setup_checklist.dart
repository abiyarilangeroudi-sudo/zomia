import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';
import '../domain/owner_setup_models.dart';
import 'owner_onboarding_presenter.dart';
import 'owner_loyalty_summary_card.dart';

class OwnerSetupChecklist extends StatelessWidget {
  const OwnerSetupChecklist({
    super.key,
    required this.state,
    this.loyaltySummary,
    required this.onCreateMission,
    required this.onCreateRewardTemplate,
    required this.onCreateCampaign,
    required this.onInviteStaff,
  });

  final OwnerOnboardingState state;
  final OwnerLoyaltySummary? loyaltySummary;
  final VoidCallback onCreateMission;
  final VoidCallback onCreateRewardTemplate;
  final VoidCallback onCreateCampaign;
  final VoidCallback onInviteStaff;

  @override
  Widget build(BuildContext context) {
    final isLoyaltyLive = state.isPilotComplete;
    final items = [
      _OwnerSetupChecklistItem(
        title: 'Create your first mission',
        subtitle: 'Define what customers earn points for.',
        isDone: state.hasMission,
        isLocked: false,
        actionLabel: 'Create',
        onPressed: onCreateMission,
      ),
      _OwnerSetupChecklistItem(
        title: 'Create your first reward template',
        subtitle: 'Set the reward customers can earn.',
        isDone: state.hasRewardTemplate,
        isLocked: false,
        actionLabel: 'Create',
        onPressed: onCreateRewardTemplate,
      ),
      _OwnerSetupChecklistItem(
        title: 'Activate your first campaign',
        subtitle: state.canCreateCampaign
            ? 'Launch a campaign that staff and customers can use.'
            : 'Create a mission and reward template first.',
        isDone: state.hasActiveCampaign,
        isLocked: !state.canCreateCampaign,
        actionLabel: 'Activate',
        onPressed: state.canCreateCampaign ? onCreateCampaign : null,
      ),
      _OwnerSetupChecklistItem(
        title: 'Invite your first staff member',
        subtitle: 'Staff can scan customer QR codes and register actions.',
        isDone: state.hasStaff,
        isLocked: false,
        actionLabel: 'Invite',
        onPressed: onInviteStaff,
      ),
    ];

    return AppCard(
      variant: isLoyaltyLive ? AppCardVariant.highlight : AppCardVariant.normal,
      padding: isLoyaltyLive ? EdgeInsets.zero : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!state.isFirstSetupComplete) ...[
            SectionHeader(
              title: 'First setup',
              subtitle:
                  '${state.firstSetupCompletedCount} of ${state.firstSetupTaskCount} steps complete',
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: item,
              ),
            ),
          ] else if (!state.isPilotComplete) ...[
            const _OwnerMilestoneSummary(
              title: 'First setup complete',
              subtitle: 'Setup tasks are done.',
            ),
            const SizedBox(height: 16),
            const SectionHeader(
              title: 'Pilot tasks',
              subtitle: 'Complete these steps during the first pilot flow.',
            ),
            const SizedBox(height: 12),
            _OwnerPilotTaskItem(
              title: 'Staff accepts invitation',
              subtitle: 'Open the email, set a password, and sign in.',
              isDone: state.hasActiveStaff,
            ),
            const SizedBox(height: 8),
            _OwnerPilotTaskItem(
              title: 'Staff registers first action',
              subtitle:
                  'Serve the first customer and register a mission action.',
              isDone: state.hasMissionProgressActivity,
            ),
          ] else ...[
            OwnerLoyaltySummaryCard(summary: loyaltySummary),
          ],
        ],
      ),
    );
  }
}

class _OwnerMilestoneSummary extends StatelessWidget {
  const _OwnerMilestoneSummary({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppListRow(
      title: title,
      subtitle: subtitle,
      leadingIcon: Icons.check_circle_rounded,
      trailing: const StatusBadge(label: 'Done', tone: BadgeTone.success),
    );
  }
}

class _OwnerSetupChecklistItem extends StatelessWidget {
  const _OwnerSetupChecklistItem({
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.isLocked,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final bool isDone;
  final bool isLocked;
  final String actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final icon = isDone
        ? Icons.check_circle_rounded
        : isLocked
        ? Icons.lock_outline_rounded
        : Icons.radio_button_unchecked_rounded;
    final badge = isDone
        ? const StatusBadge(label: 'Done', tone: BadgeTone.success)
        : isLocked
        ? const StatusBadge(label: 'Locked', tone: BadgeTone.neutral)
        : TextButton(onPressed: onPressed, child: Text(actionLabel));

    return AppListRow(
      title: title,
      subtitle: subtitle,
      leadingIcon: icon,
      trailing: badge,
      onTap: isDone || isLocked ? null : onPressed,
    );
  }
}

class _OwnerPilotTaskItem extends StatelessWidget {
  const _OwnerPilotTaskItem({
    required this.title,
    required this.subtitle,
    required this.isDone,
  });

  final String title;
  final String subtitle;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    return AppListRow(
      title: title,
      subtitle: subtitle,
      leadingIcon: isDone
          ? Icons.check_circle_rounded
          : Icons.radio_button_unchecked_rounded,
      trailing: StatusBadge(
        label: isDone ? 'Done' : 'Next',
        tone: isDone ? BadgeTone.success : BadgeTone.warning,
      ),
    );
  }
}
