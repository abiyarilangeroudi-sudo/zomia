import '../../../app/ui/status_badge.dart';
import '../domain/customer_status.dart';

class CustomerRewardEntry {
  const CustomerRewardEntry({required this.businessName, required this.reward});

  final String businessName;
  final CustomerReward reward;
}

List<CustomerRewardEntry> customerActiveRewardEntries(CustomerStatus? status) {
  if (status == null) {
    return const [];
  }

  return [
    for (final business in status.businesses)
      for (final reward in business.rewards)
        if (reward.status == 'active')
          CustomerRewardEntry(
            businessName: business.businessName,
            reward: reward,
          ),
  ];
}

int customerActiveCampaignCount(
  List<CustomerCampaignProgress> campaignProgresses,
) {
  return campaignProgresses
      .where((progress) => progress.campaignTimeStatus == 'active')
      .length;
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
  return 'Expires ${customerFormatDateTime(reward.expiresAt)}';
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
