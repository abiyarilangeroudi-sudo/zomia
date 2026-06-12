import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/brand/brand_colors.dart';
import '../../../app/brand/brand_spacing.dart';
import '../../staff_context/domain/staff_context.dart';
import '../data/staff_service_repository.dart';
import '../domain/qr_token_input.dart';
import '../domain/staff_service_models.dart';

class StaffServicePanel extends ConsumerStatefulWidget {
  const StaffServicePanel({super.key, required this.business});

  final StaffBusiness business;

  @override
  ConsumerState<StaffServicePanel> createState() => _StaffServicePanelState();
}

class _StaffServicePanelState extends ConsumerState<StaffServicePanel> {
  final _qrTokenController = TextEditingController();
  final Map<String, int> _quantities = {};

  List<StaffServiceMission> _missions = [];
  StaffServiceSummary? _summary;
  String? _error;
  String? _success;
  bool _isLoadingMissions = true;
  bool _isResolving = false;
  bool _isSubmittingAction = false;
  String? _rewardInUseId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMissions());
  }

  @override
  void didUpdateWidget(covariant StaffServicePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.business.id != widget.business.id) {
      _summary = null;
      _quantities.clear();
      _qrTokenController.clear();
      _loadMissions();
    }
  }

  @override
  void dispose() {
    _qrTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedItems = _selectedItems();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _QrResolveCard(
          controller: _qrTokenController,
          isLoading: _isResolving,
          onScan: _scanQr,
          onResolve: _resolveQr,
        ),
        const SizedBox(height: 16),
        if (_error != null) _MessageBanner(message: _error!, isError: true),
        if (_success != null)
          _MessageBanner(message: _success!, isError: false),
        if (_error != null || _success != null) const SizedBox(height: 16),
        _CustomerSummaryCard(summary: _summary),
        const SizedBox(height: 16),
        _MissionCard(
          missions: _missions,
          quantities: _quantities,
          isLoading: _isLoadingMissions,
          isEnabled: _summary != null && !_isSubmittingAction,
          selectedPoints: selectedItems.fold<int>(
            0,
            (total, item) =>
                total + item.quantity * _pointValue(item.missionId),
          ),
          onIncrement: _incrementMission,
          onDecrement: _decrementMission,
          onSubmit: selectedItems.isEmpty ? null : _submitAction,
          isSubmitting: _isSubmittingAction,
        ),
        const SizedBox(height: 16),
        _RewardsCard(
          rewards: _summary?.activeRewards ?? const [],
          rewardInUseId: _rewardInUseId,
          onUseReward: _useReward,
        ),
        const SizedBox(height: 16),
        _RecentActionsCard(actions: _summary?.recentActions ?? const []),
      ],
    );
  }

  Future<void> _loadMissions() async {
    setState(() {
      _isLoadingMissions = true;
      _error = null;
    });
    try {
      final missions = await ref
          .read(staffServiceRepositoryProvider)
          .listMissions(businessId: widget.business.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _missions = missions;
        _isLoadingMissions = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _isLoadingMissions = false;
      });
    }
  }

  Future<void> _resolveQr() async {
    final token = normalizeQrTokenInput(_qrTokenController.text);
    if (token.isEmpty) {
      setState(() {
        _error = 'Enter a customer QR token.';
        _success = null;
      });
      return;
    }

    setState(() {
      _isResolving = true;
      _error = null;
      _success = null;
    });
    try {
      final summary = await ref
          .read(staffServiceRepositoryProvider)
          .resolveQr(businessId: widget.business.id, token: token);
      if (!mounted) {
        return;
      }
      setState(() {
        _qrTokenController.text = token;
        _summary = summary;
        _quantities.clear();
        _isResolving = false;
        _success = 'Customer loaded.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _isResolving = false;
      });
    }
  }

  Future<void> _scanQr() async {
    final token = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _QrScannerSheet(),
    );

    if (!mounted || token == null || token.trim().isEmpty) {
      return;
    }

    _qrTokenController.text = normalizeQrTokenInput(token);
    await _resolveQr();
  }

  Future<void> _submitAction() async {
    final token = normalizeQrTokenInput(_qrTokenController.text);
    final items = _selectedItems();
    if (_summary == null || token.isEmpty || items.isEmpty) {
      return;
    }

    setState(() {
      _isSubmittingAction = true;
      _error = null;
      _success = null;
    });
    try {
      final result = await ref
          .read(staffServiceRepositoryProvider)
          .registerAction(
            businessId: widget.business.id,
            qrToken: token,
            idempotencyKey: _newIdempotencyKey('action'),
            items: items,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _summary = result.summary;
        _quantities.clear();
        _isSubmittingAction = false;
        _success = 'Action registered. ${result.pointsGranted} points added.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _isSubmittingAction = false;
      });
    }
  }

  Future<void> _useReward(GeneratedReward reward) async {
    final token = normalizeQrTokenInput(_qrTokenController.text);
    if (_summary == null || token.isEmpty) {
      return;
    }

    setState(() {
      _rewardInUseId = reward.id;
      _error = null;
      _success = null;
    });
    try {
      final result = await ref
          .read(staffServiceRepositoryProvider)
          .useReward(
            businessId: widget.business.id,
            qrToken: token,
            rewardId: reward.id,
            idempotencyKey: _newIdempotencyKey('reward'),
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _summary = result.summary;
        _rewardInUseId = null;
        _success = 'Reward used.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _rewardInUseId = null;
      });
    }
  }

  void _incrementMission(StaffServiceMission mission) {
    setState(() {
      _quantities[mission.id] = (_quantities[mission.id] ?? 0) + 1;
    });
  }

  void _decrementMission(StaffServiceMission mission) {
    setState(() {
      final next = (_quantities[mission.id] ?? 0) - 1;
      if (next <= 0) {
        _quantities.remove(mission.id);
      } else {
        _quantities[mission.id] = next;
      }
    });
  }

  List<StaffServiceActionItem> _selectedItems() {
    return _quantities.entries
        .where((entry) => entry.value > 0)
        .map(
          (entry) => StaffServiceActionItem(
            missionId: entry.key,
            quantity: entry.value,
          ),
        )
        .toList();
  }

  int _pointValue(String missionId) {
    return _missions
        .firstWhere((mission) => mission.id == missionId)
        .pointValue;
  }

  String _newIdempotencyKey(String prefix) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return 'staff-${widget.business.id}-$prefix-$timestamp';
  }
}

class _QrResolveCard extends StatelessWidget {
  const _QrResolveCard({
    required this.controller,
    required this.isLoading,
    required this.onScan,
    required this.onResolve,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onScan;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BrandSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Customer QR', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Scan the customer QR code. Manual token entry remains available as a fallback.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: BrandColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isLoading ? null : onScan,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan with camera'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Manual token fallback',
                hintText: 'Paste or type customer QR token',
                prefixIcon: Icon(Icons.qr_code_2),
              ),
              onSubmitted: (_) => onResolve(),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: isLoading ? null : onResolve,
              icon: isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: const Text('Resolve customer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrScannerSheet extends StatefulWidget {
  const _QrScannerSheet();

  @override
  State<_QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<_QrScannerSheet> {
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
              ClipRRect(
                borderRadius: BorderRadius.circular(BrandSpacing.smallRadius),
                child: SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.55,
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

class _CustomerSummaryCard extends StatelessWidget {
  const _CustomerSummaryCard({required this.summary});

  final StaffServiceSummary? summary;

  @override
  Widget build(BuildContext context) {
    final summary = this.summary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BrandSpacing.cardPadding),
        child: summary == null
            ? const _EmptyPanelState(
                icon: Icons.person_search,
                title: 'No customer loaded',
                message: 'Scan a customer QR to start the service session.',
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.customer.fullName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(summary.customer.email),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.stars, color: BrandColors.orange),
                      const SizedBox(width: 8),
                      Text(
                        '${summary.points} points',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.missions,
    required this.quantities,
    required this.isLoading,
    required this.isEnabled,
    required this.selectedPoints,
    required this.onIncrement,
    required this.onDecrement,
    required this.onSubmit,
    required this.isSubmitting,
  });

  final List<StaffServiceMission> missions;
  final Map<String, int> quantities;
  final bool isLoading;
  final bool isEnabled;
  final int selectedPoints;
  final void Function(StaffServiceMission mission) onIncrement;
  final void Function(StaffServiceMission mission) onDecrement;
  final VoidCallback? onSubmit;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
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
                    'Register Action',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.stars, size: 16),
                  label: Text('$selectedPoints pts'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (missions.isEmpty)
              const _EmptyPanelState(
                icon: Icons.task_alt,
                title: 'No missions',
                message: 'No active missions are available for this business.',
              )
            else
              ...missions.map(
                (mission) => _MissionRow(
                  mission: mission,
                  quantity: quantities[mission.id] ?? 0,
                  isEnabled: isEnabled,
                  onIncrement: () => onIncrement(mission),
                  onDecrement: () => onDecrement(mission),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: isEnabled && !isSubmitting ? onSubmit : null,
              icon: isSubmitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle),
              label: const Text('Register action'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  const _MissionRow({
    required this.mission,
    required this.quantity,
    required this.isEnabled,
    required this.onIncrement,
    required this.onDecrement,
  });

  final StaffServiceMission mission;
  final int quantity;
  final bool isEnabled;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: BrandColors.line),
          borderRadius: BorderRadius.circular(BrandSpacing.smallRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text('${mission.pointValue} points each'),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Decrease',
                onPressed: isEnabled && quantity > 0 ? onDecrement : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '$quantity',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Increase',
                onPressed: isEnabled ? onIncrement : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardsCard extends StatelessWidget {
  const _RewardsCard({
    required this.rewards,
    required this.rewardInUseId,
    required this.onUseReward,
  });

  final List<GeneratedReward> rewards;
  final String? rewardInUseId;
  final void Function(GeneratedReward reward) onUseReward;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BrandSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Active Rewards',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (rewards.isEmpty)
              const _EmptyPanelState(
                icon: Icons.redeem,
                title: 'No active rewards',
                message: 'Available rewards will appear after customer lookup.',
              )
            else
              ...rewards.map(
                (reward) => _RewardRow(
                  reward: reward,
                  isLoading: rewardInUseId == reward.id,
                  onUse: () => onUseReward(reward),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.reward,
    required this.isLoading,
    required this.onUse,
  });

  final GeneratedReward reward;
  final bool isLoading;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BrandColors.orange.withValues(alpha: 0.08),
          border: Border.all(color: BrandColors.orange),
          borderRadius: BorderRadius.circular(BrandSpacing.smallRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.card_giftcard, color: BrandColors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(reward.displayValue),
                  ],
                ),
              ),
              TextButton(
                onPressed: isLoading ? null : onUse,
                child: isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Use'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActionsCard extends StatelessWidget {
  const _RecentActionsCard({required this.actions});

  final List<StaffRecentAction> actions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(BrandSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Recent Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (actions.isEmpty)
              const _EmptyPanelState(
                icon: Icons.history,
                title: 'No recent actions',
                message: 'Customer activity will appear after service starts.',
              )
            else
              ...actions.map(
                (action) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.receipt_long),
                  title: Text(action.actionType.replaceAll('_', ' ')),
                  subtitle: Text(_formatDateTime(action.occurredAt)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? BrandColors.error : BrandColors.success;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(BrandSpacing.smallRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(message, style: TextStyle(color: color)),
      ),
    );
  }
}

class _EmptyPanelState extends StatelessWidget {
  const _EmptyPanelState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Icon(icon, color: BrandColors.textSecondary),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: BrandColors.textSecondary),
          ),
        ],
      ),
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
