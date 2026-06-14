import 'package:flutter/material.dart';

import '../brand/brand_colors.dart';
import 'status_badge.dart';
import 'app_button.dart';
import 'app_card.dart';

enum RewardCardVariant { customer, staffAction }

class RewardCard extends StatelessWidget {
  const RewardCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.expiresLabel,
    this.businessName,
    this.variant = RewardCardVariant.customer,
    this.isLoading = false,
    this.onUse,
  });

  final String title;
  final String subtitle;
  final String expiresLabel;
  final String? businessName;
  final RewardCardVariant variant;
  final bool isLoading;
  final VoidCallback? onUse;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                backgroundColor: BrandColors.purple,
                foregroundColor: BrandColors.surface,
                child: Icon(Icons.card_giftcard_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    if (businessName != null) ...[
                      Text(
                        businessName!,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: BrandColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(subtitle),
                  ],
                ),
              ),
              const StatusBadge(label: 'Active', tone: BadgeTone.success),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            expiresLabel,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: BrandColors.textSecondary),
          ),
          if (variant == RewardCardVariant.staffAction) ...[
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Use Reward',
              icon: Icons.redeem_rounded,
              onPressed: isLoading ? null : onUse,
              isLoading: isLoading,
            ),
          ],
        ],
      ),
    );
  }
}
