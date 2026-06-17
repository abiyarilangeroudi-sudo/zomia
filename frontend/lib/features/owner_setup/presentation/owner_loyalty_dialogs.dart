import 'package:flutter/material.dart';

import 'owner_campaign_widgets.dart';
import 'owner_loyalty_actions.dart';
import 'owner_mission_widgets.dart';
import 'owner_reward_template_widgets.dart';
import 'owner_setup_controller.dart';

Future<void> openOwnerLoyaltyCreateDialog(
  BuildContext context,
  OwnerSetupController controller,
) async {
  final action = await showOwnerLoyaltyCreateActions(context);
  if (!context.mounted || action == null) {
    return;
  }
  switch (action) {
    case OwnerLoyaltyCreateAction.mission:
      await _openMissionDialog(context, controller);
    case OwnerLoyaltyCreateAction.campaign:
      await _openCampaignDialog(context, controller);
    case OwnerLoyaltyCreateAction.rewardTemplate:
      await _openRewardTemplateDialog(context, controller);
  }
}

Future<void> _openMissionDialog(
  BuildContext context,
  OwnerSetupController controller,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) => OwnerMissionCreateDialog(
          controller: controller.missionNameController,
          pointsController: controller.missionPointsController,
          errorMessage: controller.error,
          isSaving: controller.isSaving,
          onCreate: controller.createMission,
        ),
      ),
    ),
  );
}

Future<void> _openCampaignDialog(
  BuildContext context,
  OwnerSetupController controller,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) => OwnerCampaignCreateDialog(
          controller: controller.campaignNameController,
          thresholdController: controller.campaignThresholdController,
          startDate: controller.campaignStartDate,
          endDate: controller.campaignEndDate,
          maxCompletionsController: controller.campaignMaxCompletionsController,
          missions: controller.missions,
          selectedMissionIds: controller.selectedMissionIds,
          isRepeatable: controller.campaignIsRepeatable,
          hasCompletionLimit: controller.campaignHasCompletionLimit,
          errorMessage: controller.error,
          isSaving: controller.isSaving,
          onMissionToggled: controller.toggleMission,
          onRepeatableChanged: controller.setCampaignRepeatable,
          onCompletionLimitChanged: controller.setCampaignCompletionLimit,
          onStartDateChanged: controller.setCampaignStartDate,
          onEndDateChanged: controller.setCampaignEndDate,
          onCreate: controller.createCampaign,
        ),
      ),
    ),
  );
}

Future<void> _openRewardTemplateDialog(
  BuildContext context,
  OwnerSetupController controller,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) => OwnerRewardTemplateCreateDialog(
          rewardNameController: controller.rewardNameController,
          giftNameController: controller.giftNameController,
          validDaysController: controller.validDaysController,
          campaigns: controller.campaigns,
          selectedCampaignId: controller.selectedCampaignId,
          errorMessage: controller.error,
          isSaving: controller.isSaving,
          onCampaignChanged: controller.selectCampaign,
          onCreate: controller.createRewardTemplate,
        ),
      ),
    ),
  );
}
