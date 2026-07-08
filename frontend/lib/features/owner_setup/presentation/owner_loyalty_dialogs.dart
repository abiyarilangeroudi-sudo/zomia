import 'package:flutter/material.dart';

import '../domain/owner_setup_models.dart';
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
  controller.startCreateMission();
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) => OwnerMissionCreateDialog(
          controller: controller.missionForm.nameController,
          pointsController: controller.missionForm.pointsController,
          title: 'Create Mission',
          actionLabel: 'Create Mission',
          actionIcon: Icons.add_task_rounded,
          errorMessage: controller.error,
          onClearError: controller.clearError,
          isSaving: controller.isSaving,
          onCreate: controller.createMission,
        ),
      ),
    ),
  );
}

Future<void> openOwnerMissionEditDialog(
  BuildContext context,
  OwnerSetupController controller,
  OwnerMission mission,
) {
  controller.startEditMission(mission);
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) => OwnerMissionCreateDialog(
          controller: controller.missionForm.nameController,
          pointsController: controller.missionForm.pointsController,
          title: 'Edit Mission',
          actionLabel: 'Save Mission',
          actionIcon: Icons.save_rounded,
          errorMessage: controller.error,
          onClearError: controller.clearError,
          isSaving: controller.isSaving,
          onCreate: () => controller.updateMission(mission),
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
  controller.startCreateRewardTemplate();
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) => OwnerRewardTemplateCreateDialog(
          giftNameController: controller.rewardTemplateForm.giftNameController,
          validDaysController:
              controller.rewardTemplateForm.validDaysController,
          title: 'Create Reward Template',
          actionLabel: 'Create Template',
          actionIcon: Icons.card_giftcard_rounded,
          errorMessage: controller.error,
          onClearError: controller.clearError,
          isSaving: controller.isSaving,
          onCreate: controller.createRewardTemplate,
        ),
      ),
    ),
  );
}

Future<void> openOwnerRewardTemplateEditDialog(
  BuildContext context,
  OwnerSetupController controller,
  OwnerRewardTemplate template,
) {
  controller.startEditRewardTemplate(template);
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) => OwnerRewardTemplateCreateDialog(
          giftNameController: controller.rewardTemplateForm.giftNameController,
          validDaysController:
              controller.rewardTemplateForm.validDaysController,
          title: 'Edit Reward Template',
          actionLabel: 'Save Template',
          actionIcon: Icons.save_rounded,
          errorMessage: controller.error,
          onClearError: controller.clearError,
          isSaving: controller.isSaving,
          onCreate: () => controller.updateRewardTemplate(template),
        ),
      ),
    ),
  );
}
