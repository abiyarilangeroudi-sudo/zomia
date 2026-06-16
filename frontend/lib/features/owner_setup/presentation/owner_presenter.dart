import '../../../app/ui/ui.dart';
import '../domain/owner_setup_models.dart';

class OwnerActivityPresentation {
  const OwnerActivityPresentation({
    required this.subtitle,
    required this.badgeLabel,
    required this.badgeTone,
  });

  final String subtitle;
  final String badgeLabel;
  final BadgeTone badgeTone;
}

class OwnerStaffTogglePresentation {
  const OwnerStaffTogglePresentation({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.tone,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final ConfirmTone tone;
}

String ownerCampaignSubtitle(OwnerCampaign campaign) {
  final repeatableLabel = campaign.isRepeatable
      ? campaign.maxCompletionsPerCustomer == null
            ? 'repeatable · unlimited within dates'
            : 'repeatable · max ${campaign.maxCompletionsPerCustomer}'
      : 'non-repeatable';
  return '${campaign.thresholdPoints} pts · $repeatableLabel · ${campaign.status}';
}

String ownerRewardTemplateSubtitle(OwnerRewardTemplate template) {
  return '${template.giftName ?? template.rewardType} · ${template.validDays} days';
}

String ownerStaffStatusLabel(OwnerStaffMember staffMember) {
  return staffMember.isActive ? 'Active' : 'Inactive';
}

BadgeTone ownerStaffStatusTone(OwnerStaffMember staffMember) {
  return staffMember.isActive ? BadgeTone.success : BadgeTone.neutral;
}

OwnerStaffTogglePresentation ownerStaffTogglePresentation(bool nextActive) {
  return OwnerStaffTogglePresentation(
    title: nextActive ? 'Activate Staff?' : 'Deactivate Staff?',
    message: nextActive
        ? 'This staff member will regain access to this business.'
        : 'This staff member will lose access to this business. History remains unchanged.',
    confirmLabel: nextActive ? 'Activate' : 'Deactivate',
    tone: nextActive ? ConfirmTone.standard : ConfirmTone.destructive,
  );
}

OwnerActivityPresentation ownerActivityPresentation(OwnerActivity activity) {
  final hasPoints = activity.pointsGranted > 0;
  return OwnerActivityPresentation(
    subtitle:
        '${activity.customerName} · ${activity.staffName} · ${ownerFormatActivityTime(activity.createdAt)}',
    badgeLabel: hasPoints
        ? '+${activity.pointsGranted} pts'
        : activity.actionType.replaceAll('_', ' '),
    badgeTone: hasPoints ? BadgeTone.success : BadgeTone.neutral,
  );
}

String ownerFormatActivityTime(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$month/$day $hour:$minute';
}
