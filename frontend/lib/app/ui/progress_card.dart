import 'package:flutter/material.dart';

import '../brand/brand_colors.dart';
import '../brand/brand_spacing.dart';
import 'status_badge.dart';
import 'app_card.dart';

class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.label,
    required this.badgeLabel,
    required this.badgeTone,
    this.timeRangeLabel,
  });

  final String title;
  final String subtitle;
  final double value;
  final String label;
  final String badgeLabel;
  final BadgeTone badgeTone;
  final String? timeRangeLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final normalizedValue = value.clamp(0.0, 1.0);
    return AppCard(
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        color: BrandColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleLarge?.copyWith(height: 1.12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              StatusBadge(label: badgeLabel, tone: badgeTone),
            ],
          ),
          const SizedBox(height: 18),
          _ProgressTrack(value: normalizedValue),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              color: BrandColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (timeRangeLabel != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  size: 16,
                  color: BrandColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    timeRangeLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: BrandColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(BrandSpacing.smallRadius),
      child: SizedBox(
        height: 8,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: BrandColors.orange.withValues(alpha: 0.22),
              ),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: const DecoratedBox(
                decoration: BoxDecoration(color: BrandColors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
