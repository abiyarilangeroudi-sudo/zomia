import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/brand/brand_colors.dart';
import '../../../app/brand/brand_spacing.dart';
import '../../auth/domain/current_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/customer_qr_repository.dart';
import '../domain/customer_qr_token.dart';

class CustomerQrScreen extends ConsumerStatefulWidget {
  const CustomerQrScreen({super.key, required this.user});

  final CurrentUser user;

  @override
  ConsumerState<CustomerQrScreen> createState() => _CustomerQrScreenState();
}

class _CustomerQrScreenState extends ConsumerState<CustomerQrScreen> {
  CustomerQrToken? _token;
  String? _error;
  bool _isLoading = true;
  bool _isRotating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _issueToken());
  }

  @override
  Widget build(BuildContext context) {
    final token = _token;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My QR'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(BrandSpacing.screenPadding),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(BrandSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.user.fullName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(widget.user.email),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(BrandSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Customer QR',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_error != null)
                    _ErrorState(message: _error!, onRetry: _issueToken)
                  else if (token != null)
                    _QrTokenView(token: token),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _isLoading || _isRotating ? null : _rotateToken,
                    icon: _isRotating
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text('Rotate QR'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _issueToken() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = await ref.read(customerQrRepositoryProvider).issueToken();
      if (!mounted) {
        return;
      }
      setState(() {
        _token = token;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _rotateToken() async {
    setState(() {
      _isRotating = true;
      _error = null;
    });
    try {
      final token = await ref.read(customerQrRepositoryProvider).rotateToken();
      if (!mounted) {
        return;
      }
      setState(() {
        _token = token;
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

class _QrTokenView extends StatelessWidget {
  const _QrTokenView({required this.token});

  final CustomerQrToken token;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: BrandColors.line),
            borderRadius: BorderRadius.circular(BrandSpacing.cardRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: QrImageView(
              data: token.qrPayload,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SelectableText(
          token.token,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: BrandColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Text('Expires ${_formatDateTime(token.expiresAt)}'),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.error_outline, color: BrandColors.error),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
      ],
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
