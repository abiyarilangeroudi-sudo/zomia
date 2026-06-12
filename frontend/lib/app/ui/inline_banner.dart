import 'package:flutter/material.dart';

import '../brand/brand_colors.dart';
import '../brand/brand_spacing.dart';

enum BannerTone { success, error, info, warning }

class InlineBanner extends StatelessWidget {
  const InlineBanner({
    super.key,
    required this.message,
    this.tone = BannerTone.info,
    this.onClose,
  });

  final String message;
  final BannerTone tone;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      BannerTone.success => BrandColors.success,
      BannerTone.error => BrandColors.error,
      BannerTone.warning => BrandColors.warning,
      BannerTone.info => BrandColors.info,
    };
    final icon = switch (tone) {
      BannerTone.success => Icons.check_circle_outline,
      BannerTone.error => Icons.error_outline,
      BannerTone.warning => Icons.warning_amber_rounded,
      BannerTone.info => Icons.info_outline,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.34)),
        borderRadius: BorderRadius.circular(BrandSpacing.smallRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
            if (onClose != null)
              IconButton(
                tooltip: 'Dismiss',
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}
