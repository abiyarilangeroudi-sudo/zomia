import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/brand/brand_colors.dart';
import '../../../app/brand/brand_spacing.dart';
import '../../../app/ui/ui.dart';

class QrScannerSheet extends StatefulWidget {
  const QrScannerSheet({super.key});

  @override
  State<QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<QrScannerSheet> {
  bool _hasResult = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(BrandSpacing.screenPadding),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BrandColors.surface,
          borderRadius: BorderRadius.circular(BrandSpacing.cardRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(BrandSpacing.cardPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Scan Customer QR',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ScannerSheetFrame(
                height: MediaQuery.sizeOf(context).height * 0.55,
                child: SizedBox(
                  child: MobileScanner(
                    fit: BoxFit.cover,
                    onDetect: _handleDetection,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Allow camera access, then place the customer QR inside the frame.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: BrandColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_hasResult) {
      return;
    }

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue?.trim();
      if (rawValue == null || rawValue.isEmpty) {
        continue;
      }

      _hasResult = true;
      Navigator.of(context).pop(rawValue);
      return;
    }
  }
}
