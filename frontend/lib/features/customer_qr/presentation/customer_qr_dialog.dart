import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/ui/ui.dart';
import '../data/customer_qr_repository.dart';
import '../domain/customer_qr_token.dart';
import 'customer_presenter.dart';

class CustomerQrDialog extends ConsumerStatefulWidget {
  const CustomerQrDialog({
    super.key,
    required this.token,
    required this.isLoading,
    required this.error,
    required this.onTokenChanged,
    required this.onRetry,
  });

  final CustomerQrToken? token;
  final bool isLoading;
  final String? error;
  final ValueChanged<CustomerQrToken> onTokenChanged;
  final VoidCallback onRetry;

  @override
  ConsumerState<CustomerQrDialog> createState() => _CustomerQrDialogState();
}

class _CustomerQrDialogState extends ConsumerState<CustomerQrDialog> {
  CustomerQrToken? _token;
  String? _error;
  bool _showRefreshWarning = false;
  bool _isRotating = false;

  @override
  void initState() {
    super.initState();
    _token = widget.token;
    _error = widget.error;
  }

  @override
  void didUpdateWidget(CustomerQrDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token != widget.token) {
      _token = widget.token;
    }
    if (oldWidget.error != widget.error) {
      _error = widget.error;
    }
  }

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
    final token = _token;
    if (widget.isLoading && token == null) {
      return const AppCard(child: LoadingState(label: 'Loading QR code'));
    }
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InlineBanner(message: _error!, tone: BannerTone.error),
          const SizedBox(height: 12),
          SecondaryButton(
            label: 'Try again',
            icon: Icons.refresh_rounded,
            onPressed: widget.onRetry,
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
          'Show this QR to staff. Expires ${customerFormatDateTime(token.expiresAt)}.',
      token: token.token,
      primaryActionLabel: _isRotating ? 'Refreshing' : 'Refresh QR token',
      primaryActionIcon: Icons.refresh_rounded,
      isPrimaryActionLoading: _isRotating,
      onPrimaryAction: _isRotating ? null : _refreshToken,
      fallbackContent: _showRefreshWarning
          ? const InlineBanner(
              message: 'Old QR is invalid.',
              tone: BannerTone.warning,
            )
          : null,
    );
  }

  Future<void> _refreshToken() async {
    setState(() {
      _isRotating = true;
      _error = null;
    });
    try {
      final token = await ref.read(customerQrRepositoryProvider).rotateToken();
      if (!mounted) {
        return;
      }
      widget.onTokenChanged(token);
      setState(() {
        _token = token;
        _showRefreshWarning = true;
        _isRotating = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _isRotating = false;
      });
    }
  }
}
