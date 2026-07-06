import 'package:flutter/material.dart';

import '../../../app/brand/brand_colors.dart';
import '../../../app/ui/ui.dart';

class OwnerSetupChecklist extends StatelessWidget {
  const OwnerSetupChecklist({
    super.key,
    required this.hasMission,
    required this.hasRewardTemplate,
    required this.hasCampaign,
    required this.hasStaff,
    required this.hasActiveStaff,
    required this.hasMissionProgressActivity,
    required this.onCreateMission,
    required this.onCreateRewardTemplate,
    required this.onCreateCampaign,
    required this.onInviteStaff,
  });

  final bool hasMission;
  final bool hasRewardTemplate;
  final bool hasCampaign;
  final bool hasStaff;
  final bool hasActiveStaff;
  final bool hasMissionProgressActivity;
  final VoidCallback onCreateMission;
  final VoidCallback onCreateRewardTemplate;
  final VoidCallback onCreateCampaign;
  final VoidCallback onInviteStaff;

  @override
  Widget build(BuildContext context) {
    final canCreateCampaign = hasMission && hasRewardTemplate;
    final items = [
      _OwnerSetupChecklistItem(
        title: 'Create your first mission',
        subtitle: 'Define what customers earn points for.',
        isDone: hasMission,
        isLocked: false,
        actionLabel: 'Create',
        onPressed: onCreateMission,
      ),
      _OwnerSetupChecklistItem(
        title: 'Create your first reward template',
        subtitle: 'Set the reward customers can earn.',
        isDone: hasRewardTemplate,
        isLocked: false,
        actionLabel: 'Create',
        onPressed: onCreateRewardTemplate,
      ),
      _OwnerSetupChecklistItem(
        title: 'Create your first campaign',
        subtitle: canCreateCampaign
            ? 'Connect your mission and reward.'
            : 'Create a mission and reward template first.',
        isDone: hasCampaign,
        isLocked: !canCreateCampaign,
        actionLabel: 'Create',
        onPressed: canCreateCampaign ? onCreateCampaign : null,
      ),
      _OwnerSetupChecklistItem(
        title: 'Invite your first staff member',
        subtitle: 'Staff can scan customer QR codes and register actions.',
        isDone: hasStaff,
        isLocked: false,
        actionLabel: 'Invite',
        onPressed: onInviteStaff,
      ),
    ];
    final completedCount = items.where((item) => item.isDone).length;
    final isComplete = completedCount == items.length;
    final isPilotComplete = hasActiveStaff && hasMissionProgressActivity;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isComplete) ...[
            SectionHeader(
              title: 'First setup',
              subtitle: '$completedCount of ${items.length} steps complete',
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: item,
              ),
            ),
          ] else ...[
            const _OwnerMilestoneSummary(
              title: 'First setup complete',
              subtitle: 'Setup tasks are done.',
            ),
            const SizedBox(height: 16),
            if (!isPilotComplete) ...[
              const SectionHeader(
                title: 'Pilot tasks',
                subtitle: 'Complete these steps during the first pilot flow.',
              ),
              const SizedBox(height: 12),
              _OwnerPilotTaskItem(
                title: 'Staff accepts invitation',
                subtitle: 'Open the email, set a password, and sign in.',
                isDone: hasActiveStaff,
              ),
              const SizedBox(height: 8),
              _OwnerPilotTaskItem(
                title: 'Staff registers first action',
                subtitle:
                    'Serve the first customer and register a mission action.',
                isDone: hasMissionProgressActivity,
              ),
            ] else ...[
              const _OwnerMilestoneSummary(
                title: 'Pilot tasks complete',
                subtitle: 'The first staff action has been registered.',
              ),
              const SizedBox(height: 16),
              const _OwnerActiveLoyaltySummary(),
            ],
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

class _OwnerActiveLoyaltySummary extends StatelessWidget {
  const _OwnerActiveLoyaltySummary();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.teal.withValues(alpha: 0.08),
        border: Border.all(color: BrandColors.teal.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: BrandColors.teal,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.verified_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Loyalty is active',
                    style: textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Customers can now earn points from mission actions and receive rewards when they reach the campaign target. Staff can use rewards by scanning the customer QR code.',
              style: textTheme.bodyMedium?.copyWith(
                color: BrandColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'You can review the full flow in Staff recent actions.',
              style: textTheme.bodyMedium?.copyWith(
                color: BrandColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
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
