import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';
import 'owner_campaign_widgets.dart';
import 'owner_loyalty_dialogs.dart';
import 'owner_setup_assets_card.dart';
import 'owner_setup_controller.dart';
import 'owner_setup_shared_widgets.dart';

class OwnerLoyaltyView extends StatelessWidget {
  const OwnerLoyaltyView({
    super.key,
    required this.controller,
    required this.campaignTabIndex,
  });

  final OwnerSetupController controller;
  final int campaignTabIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OwnerStatusBanners(
          error: controller.error,
          success: controller.success,
          onClearError: controller.clearError,
          onClearSuccess: controller.clearSuccess,
        ),
        if (controller.isLoading)
          const AppCard(child: LoadingState(label: 'Loading campaigns'))
        else if (controller.businesses.isEmpty)
          const OwnerNoBusinessCard()
        else ...[
          OwnerCampaignListCard(
            campaigns: controller.campaigns,
            selectedTabIndex: campaignTabIndex,
            isSaving: controller.isSaving,
            onPreviewEnd: controller.previewCampaignEnd,
            onEndCampaign: controller.endCampaign,
          ),
          const SizedBox(height: 16),
          OwnerSetupAssetsCard(
            missions: controller.missions,
            rewardTemplates: controller.rewardTemplates,
            currentMissions: () => controller.missions,
            currentRewardTemplates: () => controller.rewardTemplates,
            currentError: () => controller.error,
            currentSuccess: () => controller.success,
            onClearError: controller.clearError,
            onClearSuccess: controller.clearSuccess,
            isSaving: controller.isSaving,
            onEditMission: (mission) async =>
                openOwnerMissionEditDialog(context, controller, mission),
            onDeleteMission: controller.deleteMission,
            onArchiveMission: controller.archiveMission,
            onEditRewardTemplate: (template) async =>
                openOwnerRewardTemplateEditDialog(
                  context,
                  controller,
                  template,
                ),
            onDeleteRewardTemplate: controller.deleteRewardTemplate,
            onArchiveRewardTemplate: controller.archiveRewardTemplate,
          ),
        ],
      ],
    );
  }
}
