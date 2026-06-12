import 'package:flutter/material.dart';

import '../brand/brand_colors.dart';
import '../brand/brand_spacing.dart';

enum BadgeTone { neutral, success, warning, error, info }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = BadgeTone.neutral,
  });

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      BadgeTone.success => BrandColors.success,
      BadgeTone.warning => BrandColors.warning,
      BadgeTone.error => BrandColors.error,
      BadgeTone.info => BrandColors.info,
      BadgeTone.neutral => BrandColors.textSecondary,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.42)),
        borderRadius: BorderRadius.circular(BrandSpacing.smallRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: tone == BadgeTone.warning ? BrandColors.textPrimary : color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
