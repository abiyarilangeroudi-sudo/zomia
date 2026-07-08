import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';
import '../domain/owner_setup_models.dart';
import 'owner_mission_widgets.dart';
import 'owner_reward_template_widgets.dart';
import 'owner_setup_shared_widgets.dart';

class OwnerSetupAssetsCard extends StatefulWidget {
  const OwnerSetupAssetsCard({
    super.key,
    required this.missions,
    required this.rewardTemplates,
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
  final bool isSaving;
  final ValueChanged<OwnerMission> onEditMission;
  final Future<void> Function(OwnerMission mission) onDeleteMission;
  final Future<void> Function(OwnerMission mission) onArchiveMission;
  final ValueChanged<OwnerRewardTemplate> onEditRewardTemplate;
  final Future<void> Function(OwnerRewardTemplate template)
  onDeleteRewardTemplate;
  final Future<void> Function(OwnerRewardTemplate template)
  onArchiveRewardTemplate;

  @override
  State<OwnerSetupAssetsCard> createState() => _OwnerSetupAssetsCardState();
}

class _OwnerSetupAssetsCardState extends State<OwnerSetupAssetsCard> {
  var _showDetails = false;

  @override
  Widget build(BuildContext context) {
    return OwnerSetupCard(
      title: 'Setup assets',
      subtitle: 'Missions and reward templates used to build campaigns.',
      children: [
        AppListRow(
          title: 'Missions',
          subtitle: _countLabel(widget.missions.length, 'active mission'),
          leadingIcon: Icons.task_alt_rounded,
          trailing: StatusBadge(
            label: widget.missions.length.toString(),
            tone: BadgeTone.info,
          ),
        ),
        const SizedBox(height: 8),
        AppListRow(
          title: 'Reward templates',
          subtitle: _countLabel(
            widget.rewardTemplates.length,
            'active template',
          ),
          leadingIcon: Icons.card_giftcard_rounded,
          trailing: StatusBadge(
            label: widget.rewardTemplates.length.toString(),
            tone: BadgeTone.info,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _showDetails = !_showDetails),
            icon: Icon(
              _showDetails
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
            ),
            label: Text(_showDetails ? 'Hide details' : 'Show details'),
          ),
        ),
        if (_showDetails) ...[
          const SizedBox(height: 8),
          const SectionHeader(title: 'Missions'),
          const SizedBox(height: 8),
          OwnerMissionListContent(
            missions: widget.missions,
            isSaving: widget.isSaving,
            onEdit: widget.onEditMission,
            onDelete: widget.onDeleteMission,
            onArchive: widget.onArchiveMission,
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Reward Templates'),
          const SizedBox(height: 8),
          OwnerRewardTemplateListContent(
            rewardTemplates: widget.rewardTemplates,
            isSaving: widget.isSaving,
            onEdit: widget.onEditRewardTemplate,
            onDelete: widget.onDeleteRewardTemplate,
            onArchive: widget.onArchiveRewardTemplate,
          ),
        ],
      ],
    );
  }

  String _countLabel(int count, String singular) {
    if (count == 1) {
      return '1 $singular';
    }
    return '$count ${singular}s';
  }
}
