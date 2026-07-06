import '../domain/owner_setup_models.dart';

class OwnerOnboardingState {
  const OwnerOnboardingState({
    required this.hasMission,
    required this.hasRewardTemplate,
    required this.hasCampaign,
    required this.hasStaff,
    required this.hasActiveStaff,
    required this.hasMissionProgressActivity,
  });

  factory OwnerOnboardingState.fromData({
    required List<OwnerMission> missions,
    required List<OwnerRewardTemplate> rewardTemplates,
    required List<OwnerCampaign> campaigns,
    required List<OwnerStaffMember> staffMembers,
    required List<OwnerActivity> recentActivities,
  }) {
    return OwnerOnboardingState(
      hasMission: missions.isNotEmpty,
      hasRewardTemplate: rewardTemplates.isNotEmpty,
      hasCampaign: campaigns.isNotEmpty,
      hasStaff: staffMembers.isNotEmpty,
      hasActiveStaff: staffMembers.any(
        (staffMember) => !staffMember.isPending && staffMember.isActive,
      ),
      hasMissionProgressActivity: recentActivities.any(
        (activity) => activity.actionType == 'mission_progress',
      ),
    );
  }

  final bool hasMission;
  final bool hasRewardTemplate;
  final bool hasCampaign;
  final bool hasStaff;
  final bool hasActiveStaff;
  final bool hasMissionProgressActivity;

  bool get canCreateCampaign => hasMission && hasRewardTemplate;

  int get firstSetupCompletedCount {
    return [
      hasMission,
      hasRewardTemplate,
      hasCampaign,
      hasStaff,
    ].where((isDone) => isDone).length;
  }

  int get firstSetupTaskCount => 4;

  bool get isFirstSetupComplete {
    return firstSetupCompletedCount == firstSetupTaskCount;
  }

  bool get isPilotComplete {
    return hasActiveStaff && hasMissionProgressActivity;
  }
}
