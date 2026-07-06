import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';
import 'owner_business_widgets.dart';
import 'owner_onboarding_presenter.dart';
import 'owner_setup_checklist.dart';
import 'owner_setup_controller.dart';
import 'owner_setup_shared_widgets.dart';

class OwnerHomeView extends StatelessWidget {
  const OwnerHomeView({
    super.key,
    required this.controller,
    required this.onCreateMission,
    required this.onCreateRewardTemplate,
    required this.onCreateCampaign,
    required this.onInviteStaff,
  });

  final OwnerSetupController controller;
  final VoidCallback onCreateMission;
  final VoidCallback onCreateRewardTemplate;
  final VoidCallback onCreateCampaign;
  final VoidCallback onInviteStaff;

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
          const AppCard(child: LoadingState(label: 'Loading owner setup'))
        else if (controller.businesses.isEmpty)
          const OwnerNoBusinessCard()
        else ...[
          OwnerBusinessPicker(
            businesses: controller.businesses,
            selectedBusiness: controller.selectedBusiness,
            onChanged: controller.selectBusiness,
          ),
          const SizedBox(height: 16),
          OwnerSetupChecklist(
            state: OwnerOnboardingState.fromData(
              missions: controller.missions,
              rewardTemplates: controller.rewardTemplates,
              campaigns: controller.campaigns,
              staffMembers: controller.staffForSelectedBusiness,
              recentActivities: controller.recentActivities,
            ),
            onCreateMission: onCreateMission,
            onCreateRewardTemplate: onCreateRewardTemplate,
            onCreateCampaign: onCreateCampaign,
            onInviteStaff: onInviteStaff,
          ),
        ],
      ],
    );
  }
}
