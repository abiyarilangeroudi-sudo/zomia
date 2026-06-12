import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../brand/brand_colors.dart';
import 'app_button.dart';
import 'app_card.dart';

enum QrCardVariant { customer, staffScan }

class QrCard extends StatelessWidget {
  const QrCard({
    super.key,
    required this.title,
    required this.message,
    this.token,
    this.variant = QrCardVariant.customer,
    this.primaryActionLabel,
    this.primaryActionIcon,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.secondaryActionIcon,
    this.onSecondaryAction,
  });

  final String title;
  final String message;
  final String? token;
  final QrCardVariant variant;
  final String? primaryActionLabel;
  final IconData? primaryActionIcon;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final IconData? secondaryActionIcon;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final isCustomer = variant == QrCardVariant.customer;
    return AppCard(
      variant: isCustomer ? AppCardVariant.highlight : AppCardVariant.normal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: title, subtitle: message),
          const SizedBox(height: 16),
          if (isCustomer && token != null)
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
            const ScannerSheetFrame(compact: true),
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
              onPressed: onPrimaryAction,
            ),
          ],
          if (secondaryActionLabel != null) ...[
            const SizedBox(height: 10),
            SecondaryButton(
              label: secondaryActionLabel!,
              icon: secondaryActionIcon,
              onPressed: onSecondaryAction,
            ),
          ],
        ],
      ),
    );
  }
}

class ScannerSheetFrame extends StatelessWidget {
  const ScannerSheetFrame({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.textPrimary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SizedBox(
        height: compact ? 180 : 320,
        child: Stack(
          children: [
            const Center(
              child: Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 72,
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
