import 'package:flutter/material.dart';

import '../brand/brand_colors.dart';
import '../brand/brand_spacing.dart';

enum ZomiaBannerTone { success, error, info, warning }

class ZomiaBanner extends StatelessWidget {
  const ZomiaBanner({
    super.key,
    required this.message,
    this.tone = ZomiaBannerTone.info,
    this.onClose,
  });

  final String message;
  final ZomiaBannerTone tone;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      ZomiaBannerTone.success => BrandColors.success,
      ZomiaBannerTone.error => BrandColors.error,
      ZomiaBannerTone.warning => BrandColors.warning,
      ZomiaBannerTone.info => BrandColors.info,
    };
    final icon = switch (tone) {
      ZomiaBannerTone.success => Icons.check_circle_outline,
      ZomiaBannerTone.error => Icons.error_outline,
      ZomiaBannerTone.warning => Icons.warning_amber_rounded,
      ZomiaBannerTone.info => Icons.info_outline,
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
