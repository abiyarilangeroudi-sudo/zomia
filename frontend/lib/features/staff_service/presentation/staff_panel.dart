import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/ui/ui.dart';
import '../../../core/errors/app_exception.dart';
import '../../staff_context/domain/staff_context.dart';
import '../data/staff_service_repository.dart';
import '../domain/qr_token_input.dart';
import '../domain/staff_service_attempt_keys.dart';
import '../domain/staff_service_models.dart';
import 'qr_scanner_sheet.dart';
import 'staff_service_cards.dart';
import 'staff_service_presenter.dart';

class StaffPanel extends ConsumerStatefulWidget {
  const StaffPanel({
    super.key,
    required this.business,
    this.onServiceActivityChanged,
  });

  final StaffBusiness business;
  final VoidCallback? onServiceActivityChanged;

  @override
  ConsumerState<StaffPanel> createState() => StaffPanelState();
}

class StaffPanelState extends ConsumerState<StaffPanel> {
  final _qrTokenController = TextEditingController();
  final Map<String, int> _quantities = {};
  late final StaffServiceAttemptKeys _attemptKeys;

  List<StaffServiceMission> _missions = [];
  StaffServiceSummary? _summary;
  String? _error;
  String? _success;
  bool _isLoadingMissions = true;
  bool _isResolving = false;
  bool _isSubmittingAction = false;
  bool _isCustomerConfirmed = false;
  String? _rewardInUseId;

  @override
  void initState() {
    super.initState();
    _attemptKeys = StaffServiceAttemptKeys(_newIdempotencyKey);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMissions());
  }

  @override
  void didUpdateWidget(covariant StaffPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.business.id != widget.business.id) {
      _summary = null;
      _isCustomerConfirmed = false;
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
          InlineBanner(
            message: _error!,
            tone: BannerTone.error,
            onClose: _clearError,
          ),
        if (_success != null)
          InlineBanner(
            message: _success!,
            tone: BannerTone.success,
            onClose: _clearSuccess,
          ),
        if (_error != null || _success != null) const SizedBox(height: 16),
        StaffCustomerSummaryCard(
          summary: _summary,
          isLoading: _isResolving,
          isConfirmed: _isCustomerConfirmed,
          onScan: _scanQr,
          onConfirm: _confirmCustomer,
          onReject: _rejectCustomer,
          onCancelService: _cancelService,
        ),
        if (_summary != null && !_isCustomerConfirmed) ...[
          const SizedBox(height: 16),
          StaffCustomerRecentActionsCard(actions: _summary!.recentActions),
        ],
        if (_isCustomerConfirmed) ...[
          if (shouldShowActiveRewards(_summary)) ...[
            const SizedBox(height: 16),
            StaffRewardsCard(
              rewards: _summary!.activeRewards,
              rewardInUseId: _rewardInUseId,
              onUseReward: _useReward,
            ),
          ],
          const SizedBox(height: 16),
          StaffMissionCard(
            missions: _missions,
            quantities: _quantities,
            isLoading: _isLoadingMissions,
            isEnabled: _summary != null && !_isSubmittingAction,
            selectedPoints: selectedActionPoints(
              missions: _missions,
              quantities: _quantities,
            ),
            onIncrement: _incrementMission,
            onDecrement: _decrementMission,
            onSubmit: selectedItems.isEmpty ? null : _submitAction,
            isSubmitting: _isSubmittingAction,
          ),
          const SizedBox(height: 16),
          StaffCustomerRecentActionsCard(actions: _summary!.recentActions),
        ],
      ],
    );
  }

  void _clearError() {
    setState(() {
      _error = null;
    });
  }

  void _clearSuccess() {
    setState(() {
      _success = null;
    });
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
        _isCustomerConfirmed = false;
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
    final token = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (context) => const QrScannerSheet(),
      ),
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
    const attemptScope = 'action';
    final idempotencyKey = _attemptKeys.keyFor(
      scope: attemptScope,
      signature: _actionSignature(token, items),
      prefix: 'action',
    );

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
            idempotencyKey: idempotencyKey,
            items: items,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _attemptKeys.resolve(attemptScope);
        _clearCustomerContext();
        _isSubmittingAction = false;
        _success = actionRegisteredMessage(
          result: result,
          activeRewardIdsBefore: activeRewardIdsBefore,
        );
      });
      widget.onServiceActivityChanged?.call();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (error is! AppException || !error.isAmbiguousRetry) {
          _attemptKeys.resolve(attemptScope);
        }
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
    final attemptScope = 'reward:${reward.id}';
    final idempotencyKey = _attemptKeys.keyFor(
      scope: attemptScope,
      signature: '${widget.business.id}|$token|${reward.id}',
      prefix: 'reward',
    );

    setState(() {
      _rewardInUseId = reward.id;
      _error = null;
      _success = null;
    });
    try {
      await ref
          .read(staffServiceRepositoryProvider)
          .useReward(
            businessId: widget.business.id,
            qrToken: token,
            rewardId: reward.id,
            idempotencyKey: idempotencyKey,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _attemptKeys.resolve(attemptScope);
        _clearCustomerContext();
        _rewardInUseId = null;
        _success = rewardUsedMessage(reward);
      });
      widget.onServiceActivityChanged?.call();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (error is! AppException || !error.isAmbiguousRetry) {
          _attemptKeys.resolve(attemptScope);
        }
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

  void _confirmCustomer() {
    if (_summary == null) {
      return;
    }
    setState(() {
      _isCustomerConfirmed = true;
      _success = null;
      _error = null;
    });
  }

  void _rejectCustomer() {
    setState(() {
      _clearCustomerContext();
      _success = null;
      _error = null;
    });
  }

  void _cancelService() {
    setState(() {
      _clearCustomerContext();
      _success = null;
      _error = null;
    });
  }

  void _clearCustomerContext() {
    _summary = null;
    _isCustomerConfirmed = false;
    _quantities.clear();
    _qrTokenController.clear();
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

  String _newIdempotencyKey(String prefix) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return 'staff-${widget.business.id}-$prefix-$timestamp';
  }

  String _actionSignature(String token, List<StaffServiceActionItem> items) {
    final normalizedItems = [...items]
      ..sort((left, right) => left.missionId.compareTo(right.missionId));
    final itemSignature = normalizedItems
        .map((item) => '${item.missionId}:${item.quantity}')
        .join(',');
    return '${widget.business.id}|$token|$itemSignature';
  }

  Future<bool> _confirmRewardUse(GeneratedReward reward) async {
    return showConfirmDialog(
      context: context,
      title: 'Use reward?',
      message:
          'Use "${reward.title}" for this customer. This moves the reward to Used.',
      confirmLabel: 'Use',
    );
  }
}
