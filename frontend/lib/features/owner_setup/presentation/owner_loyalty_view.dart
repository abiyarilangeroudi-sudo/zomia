import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';
import 'owner_campaign_widgets.dart';
import 'owner_loyalty_dialogs.dart';
import 'owner_mission_widgets.dart';
import 'owner_reward_template_widgets.dart';
import 'owner_setup_controller.dart';
import 'owner_setup_shared_widgets.dart';

class OwnerLoyaltyView extends StatelessWidget {
  const OwnerLoyaltyView({super.key, required this.controller});

  final OwnerSetupController controller;

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
          OwnerMissionListCard(
            missions: controller.missions,
            isSaving: controller.isSaving,
            onEdit: (mission) =>
                openOwnerMissionEditDialog(context, controller, mission),
            onDelete: controller.deleteMission,
          ),
          const SizedBox(height: 16),
          OwnerRewardTemplateListCard(
            rewardTemplates: controller.rewardTemplates,
          ),
          const SizedBox(height: 16),
          OwnerCampaignListCard(campaigns: controller.campaigns),
        ],
      ],
    );
  }
}
