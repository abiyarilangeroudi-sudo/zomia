import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../brand/brand_colors.dart';
import 'app_button.dart';
import 'app_card.dart';

class QRCard extends StatelessWidget {
  const QRCard({
    super.key,
    required this.title,
    required this.message,
    this.token,
    this.primaryActionLabel,
    this.primaryActionIcon,
    this.isPrimaryActionLoading = false,
    this.onPrimaryAction,
    this.fallbackContent,
  });

  final String title;
  final String message;
  final String? token;
  final String? primaryActionLabel;
  final IconData? primaryActionIcon;
  final bool isPrimaryActionLoading;
  final VoidCallback? onPrimaryAction;
  final Widget? fallbackContent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: title, subtitle: message),
          const SizedBox(height: 16),
          if (token != null)
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: BrandColors.surface,
                  border: Border.all(color: BrandColors.line),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: QrImageView(
                    data: 'zomia://customer/$token',
                    version: QrVersions.auto,
                    size: 190,
                  ),
                ),
              ),
            )
          else
            fallbackContent ?? const SizedBox.shrink(),
          if (token != null) ...[
            const SizedBox(height: 12),
            SelectableText(
              token!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (primaryActionLabel != null) ...[
            const SizedBox(height: 16),
            PrimaryButton(
              label: primaryActionLabel!,
              icon: primaryActionIcon,
              isLoading: isPrimaryActionLoading,
              onPressed: onPrimaryAction,
            ),
          ],
          if (fallbackContent != null && token != null) ...[
            const SizedBox(height: 12),
            fallbackContent!,
          ],
        ],
      ),
    );
  }
}

class ScannerSheetFrame extends StatelessWidget {
  const ScannerSheetFrame({
    super.key,
    this.compact = false,
    this.height,
    this.child,
  });

  final bool compact;
  final double? height;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.textPrimary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SizedBox(
        height: height ?? (compact ? 180 : 320),
        child: Stack(
          children: [
            if (child != null)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: child,
                ),
              )
            else
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: BrandColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(18),
                    child: Icon(
                      Icons.qr_code_scanner_rounded,
                      color: BrandColors.teal,
                      size: 72,
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: BrandColors.orange, width: 2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
