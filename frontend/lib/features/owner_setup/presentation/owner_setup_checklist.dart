import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';

class OwnerSetupChecklist extends StatelessWidget {
  const OwnerSetupChecklist({
    super.key,
    required this.hasMission,
    required this.hasRewardTemplate,
    required this.hasCampaign,
    required this.hasStaff,
    required this.onCreateMission,
    required this.onCreateRewardTemplate,
    required this.onCreateCampaign,
    required this.onInviteStaff,
  });

  final bool hasMission;
  final bool hasRewardTemplate;
  final bool hasCampaign;
  final bool hasStaff;
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

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: isComplete ? 'First setup complete' : 'First setup',
            subtitle: isComplete
                ? 'Your business is ready for the first pilot flow.'
                : '$completedCount of ${items.length} steps complete',
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) =>
                Padding(padding: const EdgeInsets.only(bottom: 8), child: item),
          ),
        ],
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
