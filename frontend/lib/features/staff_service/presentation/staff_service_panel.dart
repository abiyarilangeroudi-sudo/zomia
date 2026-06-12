import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/brand/brand_colors.dart';
import '../../../app/brand/brand_spacing.dart';
import '../../../app/ui/ui.dart';
import '../../staff_context/domain/staff_context.dart';
import '../data/staff_service_repository.dart';
import '../domain/qr_token_input.dart';
import '../domain/staff_service_models.dart';

class StaffServicePanel extends ConsumerStatefulWidget {
  const StaffServicePanel({
    super.key,
    required this.business,
    this.onSummaryChanged,
  });

  final StaffBusiness business;
  final ValueChanged<StaffServiceSummary?>? onSummaryChanged;

  @override
  ConsumerState<StaffServicePanel> createState() => StaffServicePanelState();
}

class StaffServicePanelState extends ConsumerState<StaffServicePanel> {
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
      widget.onSummaryChanged?.call(null);
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
        if (_error != null)
          InlineBanner(message: _error!, tone: BannerTone.error),
        if (_success != null)
          InlineBanner(message: _success!, tone: BannerTone.success),
        if (_error != null || _success != null) const SizedBox(height: 16),
        _CustomerSummaryCard(summary: _summary, isLoading: _isResolving),
        const SizedBox(height: 16),
        _RewardsCard(
          rewards: _summary?.activeRewards ?? const [],
          rewardInUseId: _rewardInUseId,
          onUseReward: _useReward,
        ),
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
      ],
    );
  }

  Future<void> scanQrFromTopBar() => _scanQr();

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
      widget.onSummaryChanged?.call(summary);
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

    final activeRewardIdsBefore = _summary!.activeRewards
        .map((reward) => reward.id)
        .toSet();

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
        _success = _actionSuccessMessage(result, activeRewardIdsBefore);
      });
      widget.onSummaryChanged?.call(result.summary);
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

    final shouldUse = await _confirmRewardUse(reward);
    if (!mounted || !shouldUse) {
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
        _success = '${reward.title} marked as used.';
      });
      widget.onSummaryChanged?.call(result.summary);
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

  String _actionSuccessMessage(
    RegisterActionResult result,
    Set<String> activeRewardIdsBefore,
  ) {
    final newRewards = result.summary.activeRewards
        .where((reward) => !activeRewardIdsBefore.contains(reward.id))
        .toList();
    final pointsText = result.pointsGranted == 1 ? 'point' : 'points';

    if (newRewards.isNotEmpty) {
      final rewardText = newRewards.length == 1 ? 'reward' : 'rewards';
      return 'Action registered. ${result.pointsGranted} $pointsText added. ${newRewards.length} new $rewardText issued.';
    }

    return 'Action registered. ${result.pointsGranted} $pointsText added. No new reward was issued for this action.';
  }

  Future<bool> _confirmRewardUse(GeneratedReward reward) async {
    return showConfirmDialog(
      context: context,
      title: 'Use this Reward?',
      message:
          'This will mark "${reward.title}" as used for the loaded customer.',
      confirmLabel: 'Use Reward',
    );
  }
}

class _CustomerSummaryCard extends StatelessWidget {
  const _CustomerSummaryCard({required this.summary, required this.isLoading});

  final StaffServiceSummary? summary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final summary = this.summary;
    return AppCard(
      child: isLoading
          ? const LoadingState(label: 'Loading customer')
          : summary == null
          ? const EmptyStateView(
              icon: Icons.person_search_rounded,
              title: 'No customer loaded',
              message: 'Scan a customer QR to start the service session.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: summary.customer.fullName,
                  subtitle: summary.customer.email,
                  trailing: const StatusBadge(
                    label: 'Loaded',
                    tone: BadgeTone.success,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MetricPill(
                      icon: Icons.stars_rounded,
                      label: '${summary.points} points',
                      color: BrandColors.orange,
                    ),
                    MetricPill(
                      icon: Icons.redeem_rounded,
                      label: '${summary.activeRewards.length} active rewards',
                      color: BrandColors.purple,
                    ),
                    MetricPill(
                      icon: Icons.history_rounded,
                      label: '${summary.recentActions.length} recent actions',
                      color: BrandColors.info,
                    ),
                  ],
                ),
              ],
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Register Action',
            trailing: MetricPill(
              icon: Icons.stars_rounded,
              label: '$selectedPoints pts',
              color: BrandColors.orange,
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const LoadingState(label: 'Loading missions')
          else if (missions.isEmpty)
            const EmptyStateView(
              icon: Icons.task_alt_rounded,
              title: 'No missions',
              message: 'No active missions are available for this business.',
            )
          else
            ...missions.map(
              (mission) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MissionRow(
                  title: mission.name,
                  subtitle: '${mission.pointValue} points each',
                  quantity: quantities[mission.id] ?? 0,
                  isEnabled: isEnabled,
                  onIncrement: () => onIncrement(mission),
                  onDecrement: () => onDecrement(mission),
                ),
              ),
            ),
          const SizedBox(height: 4),
          PrimaryButton(
            label: 'Register Action',
            icon: Icons.check_circle_rounded,
            onPressed: isEnabled && !isSubmitting ? onSubmit : null,
            isLoading: isSubmitting,
          ),
        ],
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Active Rewards',
            subtitle: 'Confirm before marking a reward as used.',
          ),
          const SizedBox(height: 12),
          if (rewards.isEmpty)
            const EmptyStateView(
              icon: Icons.redeem_rounded,
              title: 'No active rewards',
              message: 'Available rewards will appear after customer lookup.',
            )
          else
            ...rewards.map(
              (reward) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RewardCard(
                  title: reward.title,
                  subtitle: reward.displayValue,
                  expiresLabel: _formatRewardExpires(reward),
                  variant: RewardCardVariant.staffAction,
                  isLoading: rewardInUseId == reward.id,
                  onUse: () => onUseReward(reward),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class StaffRecentActionsCard extends StatelessWidget {
  const StaffRecentActionsCard({super.key, required this.actions});

  final List<StaffRecentAction> actions;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Recent Actions'),
          const SizedBox(height: 12),
          if (actions.isEmpty)
            const EmptyStateView(
              icon: Icons.history_rounded,
              title: 'No recent actions',
              message: 'Customer activity will appear after service starts.',
            )
          else
            ...actions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppListRow(
                  title: _formatActionType(action.actionType),
                  subtitle: _formatDateTime(action.occurredAt),
                  leadingIcon: Icons.receipt_long_rounded,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _formatRewardExpires(GeneratedReward reward) {
  return 'Valid until ${_formatDate(reward.expiresAt)}';
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final date =
      '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}

String _formatActionType(String value) {
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
