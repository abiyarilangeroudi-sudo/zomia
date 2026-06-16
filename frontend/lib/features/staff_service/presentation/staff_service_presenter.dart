import '../domain/staff_service_models.dart';

int selectedActionPoints({
  required List<StaffServiceMission> missions,
  required Map<String, int> quantities,
}) {
  final pointsByMission = {
    for (final mission in missions) mission.id: mission.pointValue,
  };

  return quantities.entries.fold<int>(0, (total, entry) {
    final pointValue = pointsByMission[entry.key] ?? 0;
    return total + entry.value * pointValue;
  });
}

String actionRegisteredMessage({
  required RegisterActionResult result,
  required Set<String> activeRewardIdsBefore,
}) {
  final newRewards = result.summary.activeRewards
      .where((reward) => !activeRewardIdsBefore.contains(reward.id))
      .length;
  final pointsText = result.pointsGranted == 1 ? 'point' : 'points';

  if (newRewards > 0) {
    final rewardText = newRewards == 1 ? 'reward' : 'rewards';
    return 'Action registered. ${result.pointsGranted} $pointsText added. $newRewards new $rewardText issued.';
  }

  return 'Action registered. ${result.pointsGranted} $pointsText added. No new reward was issued for this action.';
}

String rewardUsedMessage(GeneratedReward reward) {
  return '${reward.title} marked as used.';
}

String rewardExpiresLabel(GeneratedReward reward) {
  return 'Valid until ${formatStaffDate(reward.expiresAt)}';
}

String formatStaffDate(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

String formatStaffDateTime(DateTime value) {
  final local = value.toLocal();
  final date =
      '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}

String formatStaffActionType(String value) {
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
