import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';
import '../domain/owner_setup_models.dart';
import 'owner_setup_shared_widgets.dart';

class OwnerMissionListCard extends StatelessWidget {
  const OwnerMissionListCard({
    super.key,
    required this.missions,
    required this.isSaving,
    required this.onEdit,
    required this.onDelete,
    required this.onArchive,
  });

  final List<OwnerMission> missions;
  final bool isSaving;
  final ValueChanged<OwnerMission> onEdit;
  final Future<void> Function(OwnerMission mission) onDelete;
  final Future<void> Function(OwnerMission mission) onArchive;

  @override
  Widget build(BuildContext context) {
    return OwnerSetupCard(
      title: 'Missions',
      children: [
        OwnerMissionListContent(
          missions: missions,
          isSaving: isSaving,
          onEdit: onEdit,
          onDelete: onDelete,
          onArchive: onArchive,
        ),
      ],
    );
  }
}

class OwnerMissionListContent extends StatelessWidget {
  const OwnerMissionListContent({
    super.key,
    required this.missions,
    required this.isSaving,
    required this.onEdit,
    required this.onDelete,
    required this.onArchive,
  });

  final List<OwnerMission> missions;
  final bool isSaving;
  final ValueChanged<OwnerMission> onEdit;
  final Future<void> Function(OwnerMission mission) onDelete;
  final Future<void> Function(OwnerMission mission) onArchive;

  @override
  Widget build(BuildContext context) {
    return OwnerSimpleList(
      emptyTitle: 'No missions yet',
      leadingIcon: Icons.task_alt_rounded,
      items: missions
          .map(
            (mission) => OwnerSimpleListItem(
              title: mission.name,
              subtitle: '${mission.pointValue} pts',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (mission.canEdit)
                    IconButton(
                      tooltip: 'Edit mission',
                      onPressed: isSaving ? null : () => onEdit(mission),
                      icon: const Icon(Icons.edit_rounded),
                    ),
                  if (mission.canDelete)
                    IconButton(
                      tooltip: 'Delete mission',
                      onPressed: isSaving
                          ? null
                          : () => _confirmDelete(context, mission),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  if (mission.canArchive)
                    IconButton(
                      tooltip: 'Archive mission',
                      onPressed: isSaving
                          ? null
                          : () => _confirmArchive(context, mission),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    OwnerMission mission,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Delete mission?',
      message:
          'This only works for missions that are not used in a campaign or customer action.',
      confirmLabel: 'Delete mission',
      tone: ConfirmTone.destructive,
    );
    if (!confirmed) {
      return;
    }
    await onDelete(mission);
  }

  Future<void> _confirmArchive(
    BuildContext context,
    OwnerMission mission,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Archive mission?',
      message:
          'This mission will be hidden from Loyalty setup, Staff, and new Campaigns. History remains unchanged.',
      confirmLabel: 'Archive mission',
    );
    if (!confirmed) {
      return;
    }
    await onArchive(mission);
  }
}

class OwnerMissionCreateDialog extends StatelessWidget {
  const OwnerMissionCreateDialog({
    super.key,
    required this.controller,
    required this.pointsController,
    required this.title,
    required this.actionLabel,
    required this.actionIcon,
    this.errorMessage,
    this.onClearError,
    required this.isSaving,
    required this.onCreate,
  });

  final TextEditingController controller;
  final TextEditingController pointsController;
  final String title;
  final String actionLabel;
  final IconData actionIcon;
  final String? errorMessage;
  final VoidCallback? onClearError;
  final bool isSaving;
  final Future<bool> Function() onCreate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: title, variant: AppTopBarVariant.modal),
      body: SafeArea(
        child: DashboardScroll(
          maxWidth: 640,
          child: OwnerSetupCard(
            title: 'Mission',
            children: [
              if (errorMessage != null) ...[
                InlineBanner(
                  message: errorMessage!,
                  tone: BannerTone.error,
                  onClose: onClearError,
                ),
                const SizedBox(height: 12),
              ],
              AppTextField(
                controller: controller,
                label: 'Mission name',
                hint: 'e.g. Buy a coffee',
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: pointsController,
                label: 'Points earned',
                hint: 'e.g. 1',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: actionLabel,
                icon: actionIcon,
                isLoading: isSaving,
                onPressed: isSaving
                    ? null
                    : () async {
                        final saved = await onCreate();
                        if (saved && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
