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
          controller: controller.missionForm.nameController,
          pointsController: controller.missionForm.pointsController,
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
          controller: controller.campaignForm.nameController,
          thresholdController: controller.campaignForm.thresholdController,
          startDate: controller.campaignForm.startDate,
          endDate: controller.campaignForm.endDate,
          maxCompletionsController:
              controller.campaignForm.maxCompletionsController,
          missions: controller.missions,
          rewardTemplates: controller.rewardTemplates,
          selectedMissionIds: controller.campaignForm.selectedMissionIds,
          selectedRewardTemplateId:
              controller.campaignForm.selectedRewardTemplateId,
          isRepeatable: controller.campaignForm.isRepeatable,
          hasCompletionLimit: controller.campaignForm.hasCompletionLimit,
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
          rewardNameController:
              controller.rewardTemplateForm.rewardNameController,
          giftNameController: controller.rewardTemplateForm.giftNameController,
          validDaysController:
              controller.rewardTemplateForm.validDaysController,
          errorMessage: controller.error,
          onClearError: controller.clearError,
          isSaving: controller.isSaving,
          onCreate: controller.createRewardTemplate,
        ),
      ),
    ),
  );
}
