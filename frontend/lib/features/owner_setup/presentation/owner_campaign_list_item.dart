import 'package:flutter/material.dart';

import '../../../app/brand/brand_colors.dart';
import '../../../app/ui/ui.dart';
import '../domain/owner_setup_models.dart';
import 'owner_presenter.dart';

class OwnerCampaignListItem extends StatelessWidget {
  const OwnerCampaignListItem({
    super.key,
    required this.campaign,
    required this.showStatusBadge,
    required this.trailing,
  });

  final OwnerCampaign campaign;
  final bool showStatusBadge;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.surface,
        border: Border.all(color: BrandColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: BrandColors.teal.withValues(alpha: 0.12),
              foregroundColor: BrandColors.teal,
              child: const Icon(Icons.campaign_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          campaign.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (showStatusBadge) ...[
                        const SizedBox(width: 8),
                        StatusBadge(
                          label: campaign.displayStatus,
                          tone: ownerCampaignBadgeTone(campaign),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ownerCampaignSubtitle(campaign),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: BrandColors.textSecondary,
                    ),
                  ),
                  if (campaign.activitySummary.participatingCustomerCount > 0 ||
                      campaign.activitySummary.rewardsIssuedCount > 0) ...[
                    const SizedBox(height: 8),
                    _CampaignActivitySummary(campaign: campaign),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        size: 18,
                        color: BrandColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          campaign.dateRangeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: BrandColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _CampaignActivitySummary extends StatelessWidget {
  const _CampaignActivitySummary({required this.campaign});

  final OwnerCampaign campaign;

  @override
  Widget build(BuildContext context) {
    final summary = campaign.activitySummary;
    final hasIssuedRewards = summary.rewardsIssuedCount > 0;
    final rewardStates = <String>[
      '${summary.rewardsReadyToUseCount} ready',
      '${summary.rewardsUsedCount} used',
      if (summary.rewardsExpiredCount > 0)
        '${summary.rewardsExpiredCount} expired',
    ];
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: BrandColors.textSecondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${summary.participatingCustomerCount} customer${summary.participatingCustomerCount == 1 ? '' : 's'} · ${summary.rewardsIssuedCount} reward${summary.rewardsIssuedCount == 1 ? '' : 's'}',
          style: style,
        ),
        if (hasIssuedRewards) ...[
          const SizedBox(height: 2),
          Text(rewardStates.join(' · '), style: style),
        ],
      ],
    );
  }
}
