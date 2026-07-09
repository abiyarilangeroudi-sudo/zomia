import '../domain/staff_service_models.dart';
import '../../../app/ui/status_badge.dart';

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
  if (result.idempotencyReplayed) {
    return 'Action already registered.';
  }

  final activeRewardIdsAfter = result.summary.activeRewards
      .map((reward) => reward.id)
      .toSet();
  final unlockedRewardCount = activeRewardIdsAfter
      .difference(activeRewardIdsBefore)
      .length;
  if (unlockedRewardCount > 0) {
    return 'Action registered. Reward unlocked.';
  }

  if (result.pointsGranted > 0) {
    final pointLabel = result.pointsGranted == 1 ? 'pt' : 'pts';
    return 'Action registered. +${result.pointsGranted} $pointLabel added.';
  }

  return 'Action registered.';
}

String rewardUsedMessage(GeneratedReward reward) {
  return 'Reward marked as used.';
}

String staffActionBadgeLabel(StaffRecentAction action) {
  if (action.pointsGranted > 0) {
    return '+${action.pointsGranted} pts';
  }
  return formatStaffActionType(action.actionType);
}

BadgeTone staffActionBadgeTone(StaffRecentAction action) {
  if (action.pointsGranted > 0 || action.actionType == 'reward_use') {
    return BadgeTone.success;
  }
  return BadgeTone.neutral;
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
  if (value == 'reward_use') {
    return 'Reward used';
  }
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
