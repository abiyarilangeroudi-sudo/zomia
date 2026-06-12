import 'package:flutter/material.dart';

import '../brand/brand_colors.dart';
import '../brand/brand_spacing.dart';

enum ZomiaBadgeTone { neutral, success, warning, error, info }

class ZomiaBadge extends StatelessWidget {
  const ZomiaBadge({
    super.key,
    required this.label,
    this.tone = ZomiaBadgeTone.neutral,
  });

  final String label;
  final ZomiaBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      ZomiaBadgeTone.success => BrandColors.success,
      ZomiaBadgeTone.warning => BrandColors.warning,
      ZomiaBadgeTone.error => BrandColors.error,
      ZomiaBadgeTone.info => BrandColors.info,
      ZomiaBadgeTone.neutral => BrandColors.textSecondary,
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
            color: tone == ZomiaBadgeTone.warning
                ? BrandColors.textPrimary
                : color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
