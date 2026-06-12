import 'package:flutter/material.dart';

import '../brand/brand_colors.dart';
import 'status_badge.dart';
import 'app_card.dart';

class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.label,
    this.isCompleted = false,
  });

  final String title;
  final String subtitle;
  final double value;
  final String label;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: isCompleted ? AppCardVariant.highlight : AppCardVariant.normal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: BrandColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
              StatusBadge(
                label: isCompleted ? 'Completed' : 'Active',
                tone: isCompleted ? BadgeTone.success : BadgeTone.info,
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: value.clamp(0, 1)),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: BrandColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
