import '../../../app/ui/status_badge.dart';
import '../domain/customer_status.dart';

class CustomerRewardEntry {
  const CustomerRewardEntry({required this.businessName, required this.reward});

  final String businessName;
  final CustomerReward reward;
}

class CustomerLoyaltyStep {
  const CustomerLoyaltyStep({
    required this.title,
    required this.subtitle,
    required this.isDone,
  });

  final String title;
  final String subtitle;
  final bool isDone;
}

class CustomerLoyaltyStepsState {
  const CustomerLoyaltyStepsState({required this.steps});

  final List<CustomerLoyaltyStep> steps;

  bool get isComplete => steps.every((step) => step.isDone);

  int get completedCount => steps.where((step) => step.isDone).length;

  int get taskCount => steps.length;

  CustomerLoyaltyStep? get nextStep {
    for (final step in steps) {
      if (!step.isDone) {
        return step;
      }
    }
    return null;
  }
}

CustomerLoyaltyStepsState customerLoyaltyStepsState({
  required CustomerStatus? status,
  required List<CustomerCampaignProgress> campaignProgresses,
}) {
  return CustomerLoyaltyStepsState(
    steps: [
      CustomerLoyaltyStep(
        title: 'Earn your first point',
        subtitle: 'Ask staff to scan your QR and register your visit.',
        isDone: status?.hasEarnedFirstPoint ?? false,
      ),
      CustomerLoyaltyStep(
        title: 'Earn your first reward',
        subtitle: 'Complete a campaign to unlock your first reward.',
        isDone: status?.hasEarnedFirstReward ?? false,
      ),
      CustomerLoyaltyStep(
        title: 'Use your first reward',
        subtitle: 'Show your QR to staff so they can use your reward.',
        isDone: status?.hasUsedFirstReward ?? false,
      ),
    ],
  );
}

List<CustomerRewardEntry> customerActiveRewardEntries(CustomerStatus? status) {
  return customerRewardEntriesByStatus(status, isActive: true);
}

List<CustomerRewardEntry> customerArchivedRewardEntries(
  CustomerStatus? status,
) {
  return customerRewardEntriesByStatus(status, isActive: false);
}

List<CustomerRewardEntry> customerRewardEntriesByStatus(
  CustomerStatus? status, {
  required bool isActive,
}) {
  if (status == null) {
    return const [];
  }

  return [
    for (final business in status.businesses)
      for (final reward in business.rewards)
        if ((reward.status == 'active') == isActive)
          CustomerRewardEntry(
            businessName: business.businessName,
            reward: reward,
          ),
  ];
}

String customerRewardBadgeLabel(CustomerReward reward) {
  return switch (reward.status) {
    'active' => 'Ready to use',
    'used' => 'Used',
    'expired' => 'Expired',
    _ => reward.status.replaceAll('_', ' '),
  };
}

BadgeTone customerRewardBadgeTone(CustomerReward reward) {
  return switch (reward.status) {
    'active' => BadgeTone.info,
    'used' => BadgeTone.neutral,
    'expired' => BadgeTone.warning,
    _ => BadgeTone.neutral,
  };
}

bool customerIsActiveCampaignProgress(CustomerCampaignProgress progress) {
  return progress.campaignTimeStatus == 'active' &&
      progress.progressState == 'in_progress' &&
      progress.badgeLabel == 'Active';
}

List<CustomerCampaignProgress> customerActiveCampaignProgresses(
  List<CustomerCampaignProgress> campaignProgresses,
) {
  return campaignProgresses.where(customerIsActiveCampaignProgress).toList();
}

List<CustomerCampaignProgress> customerArchivedCampaignProgresses(
  List<CustomerCampaignProgress> campaignProgresses,
) {
  return campaignProgresses
      .where((progress) => !customerIsActiveCampaignProgress(progress))
      .toList();
}

int customerActiveCampaignCount(
  List<CustomerCampaignProgress> campaignProgresses,
) {
  return customerActiveCampaignProgresses(campaignProgresses).length;
}

BadgeTone customerBadgeTone(String value) {
  return switch (value) {
    'success' => BadgeTone.success,
    'warning' => BadgeTone.warning,
    'neutral' => BadgeTone.neutral,
    _ => BadgeTone.info,
  };
}

String customerRewardExpiresLabel(CustomerReward reward) {
  if (reward.status == 'active') {
    return 'Show your QR to staff before ${customerFormatDateTime(reward.expiresAt)}';
  }
  if (reward.status == 'used' && reward.usedAt != null) {
    return 'Used ${customerFormatDateTime(reward.usedAt!)}';
  }
  return 'Expired ${customerFormatDateTime(reward.expiresAt)}';
}

String customerFormatDateTime(DateTime value) {
  final local = value.toLocal();
  final date =
      '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}

String customerFormatDateRange(DateTime startsAt, DateTime endsAt) {
  return '${customerFormatDate(startsAt)} - ${customerFormatDate(endsAt)}';
}

String customerFormatDate(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
