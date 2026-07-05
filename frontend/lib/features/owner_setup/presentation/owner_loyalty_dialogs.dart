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
      await openOwnerMissionCreateDialog(context, controller);
    case OwnerLoyaltyCreateAction.campaign:
      await openOwnerCampaignCreateDialog(context, controller);
    case OwnerLoyaltyCreateAction.rewardTemplate:
      await openOwnerRewardTemplateCreateDialog(context, controller);
  }
}

Future<void> openOwnerMissionCreateDialog(
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
          onClearError: controller.clearError,
          isSaving: controller.isSaving,
          onCreate: controller.createMission,
        ),
      ),
    ),
  );
}

Future<void> openOwnerCampaignCreateDialog(
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
          rewardTemplates: controller.rewardTemplates,
          selectedMissionIds: controller.selectedMissionIds,
          selectedRewardTemplateId: controller.selectedRewardTemplateId,
          isRepeatable: controller.campaignIsRepeatable,
          hasCompletionLimit: controller.campaignHasCompletionLimit,
          errorMessage: controller.error,
          onClearError: controller.clearError,
          isSaving: controller.isSaving,
          onMissionToggled: controller.toggleMission,
          onRewardTemplateChanged: controller.selectRewardTemplate,
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

Future<void> openOwnerRewardTemplateCreateDialog(
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
          errorMessage: controller.error,
          onClearError: controller.clearError,
          isSaving: controller.isSaving,
          onCreate: controller.createRewardTemplate,
        ),
      ),
    ),
  );
}
