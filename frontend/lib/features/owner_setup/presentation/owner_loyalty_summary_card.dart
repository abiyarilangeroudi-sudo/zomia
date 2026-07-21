import 'package:flutter/material.dart';

import '../../../app/brand/brand_colors.dart';
import '../domain/owner_setup_models.dart';

class OwnerLoyaltySummaryCard extends StatelessWidget {
  const OwnerLoyaltySummaryCard({super.key, required this.summary});

  final OwnerLoyaltySummary? summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: BrandColors.teal.withValues(alpha: 0.10),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: BrandColors.teal,
                foregroundColor: Colors.white,
                child: Icon(Icons.verified_rounded),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loyalty is active',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your first workflow is live.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: BrandColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (summary == null)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(
                  Icons.sync_problem_rounded,
                  color: BrandColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Activity summary is temporarily unavailable. Pull to refresh.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: BrandColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _OwnerLoyaltyMetricRow(
                  left: _OwnerLoyaltyMetric(
                    label: 'Customers',
                    value: summary!.participatingCustomerCount,
                    icon: Icons.people_outline_rounded,
                    color: BrandColors.teal,
                  ),
                  right: _OwnerLoyaltyMetric(
                    label: 'Rewards issued',
                    value: summary!.rewardsIssuedCount,
                    icon: Icons.card_giftcard_rounded,
                    color: BrandColors.orange,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: BrandColors.line),
                ),
                _OwnerLoyaltyMetricRow(
                  left: _OwnerLoyaltyMetric(
                    label: 'Ready to use',
                    value: summary!.rewardsReadyToUseCount,
                    icon: Icons.redeem_outlined,
                    color: BrandColors.teal,
                  ),
                  right: _OwnerLoyaltyMetric(
                    label: 'Used',
                    value: summary!.rewardsUsedCount,
                    icon: Icons.task_alt_rounded,
                    color: BrandColors.orange,
                  ),
                ),
                if (summary!.rewardsExpiredCount > 0) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, color: BrandColors.line),
                  ),
                  _OwnerLoyaltyMetric(
                    label: 'Expired',
                    value: summary!.rewardsExpiredCount,
                    icon: Icons.event_busy_outlined,
                    color: BrandColors.textSecondary,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _OwnerLoyaltyMetricRow extends StatelessWidget {
  const _OwnerLoyaltyMetricRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        Container(width: 1, height: 52, color: BrandColors.line),
        const SizedBox(width: 18),
        Expanded(child: right),
      ],
    );
  }
}

class _OwnerLoyaltyMetric extends StatelessWidget {
  const _OwnerLoyaltyMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value.toString(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                maxLines: 2,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: BrandColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
