import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/brand/brand_colors.dart';
import '../../../app/brand/brand_spacing.dart';
import '../../auth/domain/current_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/customer_qr_repository.dart';
import '../domain/customer_status.dart';
import '../domain/customer_qr_token.dart';

class CustomerQrScreen extends ConsumerStatefulWidget {
  const CustomerQrScreen({super.key, required this.user});

  final CurrentUser user;

  @override
  ConsumerState<CustomerQrScreen> createState() => _CustomerQrScreenState();
}

class _CustomerQrScreenState extends ConsumerState<CustomerQrScreen> {
  CustomerQrToken? _token;
  CustomerStatus? _status;
  String? _error;
  String? _statusError;
  bool _isLoading = true;
  bool _isLoadingStatus = true;
  bool _isRotating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _issueToken();
      _loadStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final token = _token;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer QR'),
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
                  const SizedBox(height: 12),
                  Text(
                    'Show this QR to staff to collect points or use available rewards.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: BrandColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _CustomerStatusCard(
            status: _status,
            isLoading: _isLoadingStatus,
            error: _statusError,
            onRefresh: _loadStatus,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(BrandSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ready to Scan',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Keep this screen open during service.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: BrandColors.textSecondary,
                    ),
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
                    label: const Text('Refresh QR token'),
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

  Future<void> _loadStatus() async {
    setState(() {
      _isLoadingStatus = true;
      _statusError = null;
    });
    try {
      final status = await ref.read(customerQrRepositoryProvider).getStatus();
      if (!mounted) {
        return;
      }
      setState(() {
        _status = status;
        _isLoadingStatus = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusError = error.toString();
        _isLoadingStatus = false;
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

class _CustomerStatusCard extends StatelessWidget {
  const _CustomerStatusCard({
    required this.status,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
  });

  final CustomerStatus? status;
  final bool isLoading;
  final String? error;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BrandSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'My Status',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh status',
                  onPressed: isLoading ? null : onRefresh,
                  icon: isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Refresh after staff issues or uses a reward.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: BrandColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            if (isLoading && status == null)
              const Center(child: CircularProgressIndicator())
            else if (error != null)
              _InlineError(message: error!, onRetry: onRefresh)
            else if (status == null || status.businesses.isEmpty)
              const _EmptyStatus()
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusMetric(
                    icon: Icons.redeem,
                    label: '${status.activeRewardsCount} active rewards',
                    color: BrandColors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...status.businesses.map(
                (business) => _BusinessStatusRow(business: business),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BusinessStatusRow extends StatelessWidget {
  const _BusinessStatusRow({required this.business});

  final CustomerBusinessStatus business;

  @override
  Widget build(BuildContext context) {
    final activeRewards = business.activeRewards;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: BrandColors.line),
          borderRadius: BorderRadius.circular(BrandSpacing.smallRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      business.businessName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (activeRewards.isEmpty)
                Text(
                  'No active rewards',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BrandColors.textSecondary,
                  ),
                )
              else
                ...activeRewards.map((reward) => _RewardLine(reward: reward)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardLine extends StatelessWidget {
  const _RewardLine({required this.reward});

  final CustomerReward reward;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.card_giftcard, size: 18, color: BrandColors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.title),
                Text(
                  '${reward.displayValue} · expires ${_formatDateTime(reward.expiresAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: BrandColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusMetric extends StatelessWidget {
  const _StatusMetric({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(BrandSpacing.smallRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _EmptyStatus extends StatelessWidget {
  const _EmptyStatus();

  @override
  Widget build(BuildContext context) {
    return Text(
      'No active rewards yet.',
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: BrandColors.textSecondary),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.error_outline, color: BrandColors.error),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
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
        DecoratedBox(
          decoration: BoxDecoration(
            color: BrandColors.background,
            border: Border.all(color: BrandColors.line),
            borderRadius: BorderRadius.circular(BrandSpacing.smallRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  'Manual fallback token',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: BrandColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  token.token,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: BrandColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
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
