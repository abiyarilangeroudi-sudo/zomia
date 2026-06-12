import 'package:flutter/material.dart';

import '../brand/brand_colors.dart';
import '../brand/brand_spacing.dart';

enum AppCardVariant { normal, highlight, compact }

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.normal,
    this.padding,
  });

  final Widget child;
  final AppCardVariant variant;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isHighlight = variant == AppCardVariant.highlight;
    final effectivePadding =
        padding ??
        EdgeInsets.all(
          variant == AppCardVariant.compact ? 12 : BrandSpacing.cardPadding,
        );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.surface,
        border: Border.all(
          color: isHighlight
              ? BrandColors.teal.withValues(alpha: 0.28)
              : BrandColors.line,
        ),
        borderRadius: BorderRadius.circular(BrandSpacing.cardRadius),
        boxShadow: const [
          BoxShadow(
            blurRadius: 4,
            color: Color(0x18000000),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(padding: effectivePadding, child: child),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BrandColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}
