import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';
import 'owner_setup_controller.dart';
import 'owner_setup_shared_widgets.dart';
import 'owner_staff_widgets.dart';

class OwnerTeamView extends StatelessWidget {
  const OwnerTeamView({super.key, required this.controller});

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
          const AppCard(child: LoadingState(label: 'Loading staff'))
        else if (controller.businesses.isEmpty)
          const OwnerNoBusinessCard()
        else
          OwnerStaffListCard(
            staffMembers: controller.staffForSelectedBusiness,
            isSaving: controller.isSaving,
            onSetStaffActive: controller.setStaffActive,
            onCancelInvitation: controller.cancelStaffInvitation,
          ),
      ],
    );
  }
}
