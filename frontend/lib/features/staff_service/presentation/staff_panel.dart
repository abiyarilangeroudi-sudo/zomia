import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/ui/ui.dart';
import '../../staff_context/domain/staff_context.dart';
import '../data/staff_service_repository.dart';
import '../domain/qr_token_input.dart';
import '../domain/staff_service_models.dart';
import 'qr_scanner_sheet.dart';
import 'staff_service_cards.dart';

class StaffPanel extends ConsumerStatefulWidget {
  const StaffPanel({super.key, required this.business, this.onSummaryChanged});

  final StaffBusiness business;
  final ValueChanged<StaffServiceSummary?>? onSummaryChanged;

  @override
  ConsumerState<StaffPanel> createState() => StaffPanelState();
}

class StaffPanelState extends ConsumerState<StaffPanel> {
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
  void didUpdateWidget(covariant StaffPanel oldWidget) {
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
        StaffCustomerSummaryCard(summary: _summary, isLoading: _isResolving),
        const SizedBox(height: 16),
        StaffRewardsCard(
          rewards: _summary?.activeRewards ?? const [],
          rewardInUseId: _rewardInUseId,
          onUseReward: _useReward,
        ),
        const SizedBox(height: 16),
        StaffMissionCard(
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
      builder: (context) => const QrScannerSheet(),
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
