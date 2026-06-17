import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';

enum OwnerLoyaltyCreateAction { mission, campaign, rewardTemplate }

Future<OwnerLoyaltyCreateAction?> showOwnerLoyaltyCreateActions(
  BuildContext context,
) {
  return showCreateActionSheet<OwnerLoyaltyCreateAction>(
    context: context,
    items: const [
      CreateActionSheetItem(
        value: OwnerLoyaltyCreateAction.mission,
        title: 'Create Mission',
        icon: Icons.task_alt_rounded,
      ),
      CreateActionSheetItem(
        value: OwnerLoyaltyCreateAction.rewardTemplate,
        title: 'Create Reward Template',
        icon: Icons.card_giftcard_rounded,
      ),
      CreateActionSheetItem(
        value: OwnerLoyaltyCreateAction.campaign,
        title: 'Create Campaign',
        icon: Icons.flag_rounded,
      ),
    ],
  );
}
