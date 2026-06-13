import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';
import '../domain/customer_qr_token.dart';

class CustomerQrDialog extends StatelessWidget {
  const CustomerQrDialog({
    super.key,
    required this.token,
    required this.isLoading,
    required this.isRotating,
    required this.error,
    required this.onRefresh,
    required this.onRetry,
  });

  final CustomerQrToken? token;
  final bool isLoading;
  final bool isRotating;
  final String? error;
  final VoidCallback? onRefresh;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'Customer QR', variant: AppTopBarVariant.modal),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 530),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final token = this.token;
    if (isLoading && token == null) {
      return const AppCard(child: LoadingState(label: 'Loading QR code'));
    }
    if (error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InlineBanner(message: error!, tone: BannerTone.error),
          const SizedBox(height: 12),
          SecondaryButton(
            label: 'Try again',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      );
    }
    if (token == null) {
      return const AppCard(
        child: EmptyStateView(
          icon: Icons.qr_code_rounded,
          title: 'QR code unavailable',
          message: 'Try again before service.',
        ),
      );
    }
    return QRCard(
      title: 'Ready to Scan',
      message:
          'Show this QR to staff. Expires ${_formatDateTime(token.expiresAt)}.',
      token: token.token,
      primaryActionLabel: isRotating ? 'Refreshing' : 'Refresh QR token',
      primaryActionIcon: Icons.refresh_rounded,
      onPrimaryAction: onRefresh,
    );
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final date =
      '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}
