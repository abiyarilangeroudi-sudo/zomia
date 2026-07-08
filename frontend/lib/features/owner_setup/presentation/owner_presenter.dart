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
  return '${campaign.thresholdPoints} pts · $repeatableLabel';
}

bool ownerCampaignIsArchived(OwnerCampaign campaign) {
  return campaign.status == 'ended' ||
      campaign.timeStatus == 'expired' ||
      campaign.displayStatus == 'Ended' ||
      campaign.displayStatus == 'Expired';
}

BadgeTone ownerCampaignBadgeTone(OwnerCampaign campaign) {
  return switch (campaign.badgeTone) {
    'success' => BadgeTone.success,
    'warning' => BadgeTone.warning,
    'error' => BadgeTone.error,
    'info' => BadgeTone.info,
    _ => BadgeTone.neutral,
  };
}

String ownerRewardTemplateSubtitle(OwnerRewardTemplate template) {
  return '${ownerRewardTemplateRewardItem(template)} · ${template.validDays} days';
}

String ownerRewardTemplateTypeLabel(OwnerRewardTemplate template) {
  return switch (template.rewardType) {
    'gift' => 'Gift',
    _ => template.rewardType,
  };
}

String ownerRewardTemplateRewardItem(OwnerRewardTemplate template) {
  return template.giftName ?? template.name;
}

String ownerRewardTemplateOptionLabel(OwnerRewardTemplate template) {
  return '${ownerRewardTemplateTypeLabel(template)} · ${ownerRewardTemplateRewardItem(template)}';
}

String ownerStaffStatusLabel(OwnerStaffMember staffMember) {
  if (staffMember.isPending) {
    return 'Pending';
  }
  return staffMember.isActive ? 'Active' : 'Inactive';
}

BadgeTone ownerStaffStatusTone(OwnerStaffMember staffMember) {
  if (staffMember.isPending) {
    return BadgeTone.neutral;
  }
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
