import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';
import '../domain/owner_setup_models.dart';
import 'owner_mission_widgets.dart';
import 'owner_reward_template_widgets.dart';
import 'owner_setup_shared_widgets.dart';

class OwnerSetupAssetsCard extends StatelessWidget {
  const OwnerSetupAssetsCard({
    super.key,
    required this.missions,
    required this.rewardTemplates,
    required this.currentMissions,
    required this.currentRewardTemplates,
    required this.currentError,
    required this.currentSuccess,
    required this.onClearError,
    required this.onClearSuccess,
    required this.isSaving,
    required this.onEditMission,
    required this.onDeleteMission,
    required this.onArchiveMission,
    required this.onEditRewardTemplate,
    required this.onDeleteRewardTemplate,
    required this.onArchiveRewardTemplate,
  });

  final List<OwnerMission> missions;
  final List<OwnerRewardTemplate> rewardTemplates;
  final List<OwnerMission> Function() currentMissions;
  final List<OwnerRewardTemplate> Function() currentRewardTemplates;
  final String? Function() currentError;
  final String? Function() currentSuccess;
  final VoidCallback onClearError;
  final VoidCallback onClearSuccess;
  final bool isSaving;
  final Future<void> Function(OwnerMission mission) onEditMission;
  final Future<void> Function(OwnerMission mission) onDeleteMission;
  final Future<void> Function(OwnerMission mission) onArchiveMission;
  final Future<void> Function(OwnerRewardTemplate template)
  onEditRewardTemplate;
  final Future<void> Function(OwnerRewardTemplate template)
  onDeleteRewardTemplate;
  final Future<void> Function(OwnerRewardTemplate template)
  onArchiveRewardTemplate;

  @override
  Widget build(BuildContext context) {
    return OwnerSetupCard(
      title: 'Setup assets',
      subtitle: 'Reusable pieces for building campaigns.',
      children: [
        AppListRow(
          title: 'Mission assets',
          subtitle:
              '${_countLabel(missions.length, 'active mission')} · staff actions earn points',
          leadingIcon: Icons.task_alt_rounded,
          trailing: StatusBadge(
            label: missions.length.toString(),
            tone: BadgeTone.info,
          ),
        ),
        const SizedBox(height: 8),
        AppListRow(
          title: 'Reward template assets',
          subtitle:
              '${_countLabel(rewardTemplates.length, 'active template')} · campaigns create rewards',
          leadingIcon: Icons.card_giftcard_rounded,
          trailing: StatusBadge(
            label: rewardTemplates.length.toString(),
            tone: BadgeTone.info,
          ),
        ),
        const SizedBox(height: 12),
        SecondaryButton(
          label: 'Manage assets',
          icon: Icons.tune_rounded,
          onPressed: () => _openManageAssets(context),
        ),
      ],
    );
  }

  String _countLabel(int count, String singular) {
    if (count == 1) {
      return '1 $singular';
    }
    return '$count ${singular}s';
  }

  void _openManageAssets(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => OwnerSetupAssetsDialog(
          missions: missions,
          rewardTemplates: rewardTemplates,
          currentMissions: currentMissions,
          currentRewardTemplates: currentRewardTemplates,
          currentError: currentError,
          currentSuccess: currentSuccess,
          onClearError: onClearError,
          onClearSuccess: onClearSuccess,
          isSaving: isSaving,
          onEditMission: onEditMission,
          onDeleteMission: onDeleteMission,
          onArchiveMission: onArchiveMission,
          onEditRewardTemplate: onEditRewardTemplate,
          onDeleteRewardTemplate: onDeleteRewardTemplate,
          onArchiveRewardTemplate: onArchiveRewardTemplate,
        ),
      ),
    );
  }
}

class OwnerSetupAssetsDialog extends StatefulWidget {
  const OwnerSetupAssetsDialog({
    super.key,
    required this.missions,
    required this.rewardTemplates,
    required this.currentMissions,
    required this.currentRewardTemplates,
    required this.currentError,
    required this.currentSuccess,
    required this.onClearError,
    required this.onClearSuccess,
    required this.isSaving,
    required this.onEditMission,
    required this.onDeleteMission,
    required this.onArchiveMission,
    required this.onEditRewardTemplate,
    required this.onDeleteRewardTemplate,
    required this.onArchiveRewardTemplate,
  });

  final List<OwnerMission> missions;
  final List<OwnerRewardTemplate> rewardTemplates;
  final List<OwnerMission> Function() currentMissions;
  final List<OwnerRewardTemplate> Function() currentRewardTemplates;
  final String? Function() currentError;
  final String? Function() currentSuccess;
  final VoidCallback onClearError;
  final VoidCallback onClearSuccess;
  final bool isSaving;
  final Future<void> Function(OwnerMission mission) onEditMission;
  final Future<void> Function(OwnerMission mission) onDeleteMission;
  final Future<void> Function(OwnerMission mission) onArchiveMission;
  final Future<void> Function(OwnerRewardTemplate template)
  onEditRewardTemplate;
  final Future<void> Function(OwnerRewardTemplate template)
  onDeleteRewardTemplate;
  final Future<void> Function(OwnerRewardTemplate template)
  onArchiveRewardTemplate;

  @override
  State<OwnerSetupAssetsDialog> createState() => _OwnerSetupAssetsDialogState();
}

class _OwnerSetupAssetsDialogState extends State<OwnerSetupAssetsDialog> {
  late List<OwnerMission> _missions;
  late List<OwnerRewardTemplate> _rewardTemplates;
  var _isOperationRunning = false;

  @override
  void initState() {
    super.initState();
    _missions = widget.missions;
    _rewardTemplates = widget.rewardTemplates;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(
        title: 'Setup assets',
        variant: AppTopBarVariant.modal,
      ),
      body: SafeArea(
        child: DashboardScroll(
          maxWidth: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OwnerStatusBanners(
                error: widget.currentError(),
                success: widget.currentSuccess(),
                onClearError: _clearError,
                onClearSuccess: _clearSuccess,
              ),
              OwnerSetupCard(
                title: 'Mission assets',
                subtitle:
                    'Staff can use these only when they belong to an active campaign.',
                children: [
                  OwnerMissionListContent(
                    missions: _missions,
                    isSaving: widget.isSaving || _isOperationRunning,
                    onEdit: _editMission,
                    onDelete: _deleteMission,
                    onArchive: _archiveMission,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OwnerSetupCard(
                title: 'Reward template assets',
                subtitle: 'Campaigns use these to create customer rewards.',
                children: [
                  OwnerRewardTemplateListContent(
                    rewardTemplates: _rewardTemplates,
                    isSaving: widget.isSaving || _isOperationRunning,
                    onEdit: _editRewardTemplate,
                    onDelete: _deleteRewardTemplate,
                    onArchive: _archiveRewardTemplate,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editMission(OwnerMission mission) async {
    await _runAndSync(() => widget.onEditMission(mission));
  }

  Future<void> _deleteMission(OwnerMission mission) async {
    await _runAndSync(() => widget.onDeleteMission(mission));
  }

  Future<void> _archiveMission(OwnerMission mission) async {
    await _runAndSync(() => widget.onArchiveMission(mission));
  }

  Future<void> _editRewardTemplate(OwnerRewardTemplate template) async {
    await _runAndSync(() => widget.onEditRewardTemplate(template));
  }

  Future<void> _deleteRewardTemplate(OwnerRewardTemplate template) async {
    await _runAndSync(() => widget.onDeleteRewardTemplate(template));
  }

  Future<void> _archiveRewardTemplate(OwnerRewardTemplate template) async {
    await _runAndSync(() => widget.onArchiveRewardTemplate(template));
  }

  Future<void> _runAndSync(Future<void> Function() action) async {
    setState(() => _isOperationRunning = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _isOperationRunning = false);
      }
    }
    _syncAssets();
  }

  void _syncAssets() {
    if (!mounted) {
      return;
    }
    setState(() {
      _missions = widget.currentMissions();
      _rewardTemplates = widget.currentRewardTemplates();
    });
  }

  void _clearError() {
    widget.onClearError();
    if (mounted) {
      setState(() {});
    }
  }

  void _clearSuccess() {
    widget.onClearSuccess();
    if (mounted) {
      setState(() {});
    }
  }
}
