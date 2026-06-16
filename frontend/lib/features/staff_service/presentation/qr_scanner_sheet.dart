import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/brand/brand_colors.dart';
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
    final scannerHeight = (MediaQuery.sizeOf(context).height * 0.58)
        .clamp(300.0, 560.0)
        .toDouble();
    return AppScaffold(
      maxWidth: 720,
      appBar: AppTopBar(
        title: 'Scan Customer QR',
        variant: AppTopBarVariant.modal,
      ),
      body: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(
              title: 'Customer QR',
              subtitle: 'Place the customer QR inside the frame.',
            ),
            const SizedBox(height: 16),
            ScannerSheetFrame(
              height: scannerHeight,
              child: MobileScanner(
                fit: BoxFit.cover,
                onDetect: _handleDetection,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Camera access may be requested by your browser.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: BrandColors.textSecondary,
              ),
            ),
          ],
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
