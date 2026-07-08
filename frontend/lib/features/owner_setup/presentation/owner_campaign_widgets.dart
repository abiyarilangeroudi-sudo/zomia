import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';
import '../domain/owner_setup_models.dart';
import 'owner_presenter.dart';
import 'owner_setup_shared_widgets.dart';

class OwnerCampaignListCard extends StatelessWidget {
  const OwnerCampaignListCard({
    super.key,
    required this.campaigns,
    required this.isSaving,
    required this.onStatusChanged,
  });

  final List<OwnerCampaign> campaigns;
  final bool isSaving;
  final Future<void> Function(OwnerCampaign campaign, String status)
  onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final visibleCampaigns = campaigns
        .where((campaign) => campaign.status != 'ended')
        .toList();
    return OwnerSetupCard(
      title: 'Campaigns',
      children: [
        OwnerSimpleList(
          emptyTitle: 'No campaigns yet',
          leadingIcon: Icons.campaign_rounded,
          items: visibleCampaigns
              .map(
                (campaign) => OwnerSimpleListItem(
                  title: campaign.name,
                  subtitle: ownerCampaignSubtitle(campaign),
                  trailing: _CampaignStatusActions(
                    campaign: campaign,
                    isSaving: isSaving,
                    onStatusChanged: onStatusChanged,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _CampaignStatusActions extends StatelessWidget {
  const _CampaignStatusActions({
    required this.campaign,
    required this.isSaving,
    required this.onStatusChanged,
  });

  final OwnerCampaign campaign;
  final bool isSaving;
  final Future<void> Function(OwnerCampaign campaign, String status)
  onStatusChanged;

  @override
  Widget build(BuildContext context) {
    if (campaign.status == 'ended') {
      return const StatusBadge(label: 'Ended', tone: BadgeTone.neutral);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (campaign.status == 'active')
          IconButton(
            tooltip: 'Pause campaign',
            onPressed: isSaving
                ? null
                : () => _confirmStatus(
                    context,
                    status: 'paused',
                    title: 'Pause campaign?',
                    message:
                        'Staff will stop registering new progress for this campaign until it is resumed.',
                    confirmLabel: 'Pause',
                  ),
            icon: const Icon(Icons.pause_circle_outline_rounded),
          )
        else if (campaign.status == 'paused')
          IconButton(
            tooltip: 'Resume campaign',
            onPressed: isSaving
                ? null
                : () => _confirmStatus(
                    context,
                    status: 'active',
                    title: 'Resume campaign?',
                    message:
                        'Staff can register new progress for this campaign again.',
                    confirmLabel: 'Resume',
                  ),
            icon: const Icon(Icons.play_circle_outline_rounded),
          ),
        IconButton(
          tooltip: 'End campaign',
          onPressed: isSaving
              ? null
              : () => _confirmStatus(
                  context,
                  status: 'ended',
                  title: 'End campaign?',
                  message:
                      'This campaign will stop permanently. Existing history remains unchanged.',
                  confirmLabel: 'End campaign',
                  tone: ConfirmTone.destructive,
                ),
          icon: const Icon(Icons.stop_circle_outlined),
        ),
      ],
    );
  }

  Future<void> _confirmStatus(
    BuildContext context, {
    required String status,
    required String title,
    required String message,
    required String confirmLabel,
    ConfirmTone tone = ConfirmTone.standard,
  }) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      tone: tone,
    );
    if (!confirmed) {
      return;
    }
    await onStatusChanged(campaign, status);
  }
}

class OwnerCampaignCreateDialog extends StatelessWidget {
  const OwnerCampaignCreateDialog({
    super.key,
    required this.controller,
    required this.thresholdController,
    required this.startDate,
    required this.endDate,
    required this.maxCompletionsController,
    required this.missions,
    required this.rewardTemplates,
    required this.selectedMissionIds,
    required this.selectedRewardTemplateId,
    required this.isRepeatable,
    required this.hasCompletionLimit,
    this.errorMessage,
    this.onClearError,
    required this.isSaving,
    required this.onMissionToggled,
    required this.onRewardTemplateChanged,
    required this.onRepeatableChanged,
    required this.onCompletionLimitChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onCreate,
  });

  final TextEditingController controller;
  final TextEditingController thresholdController;
  final DateTime startDate;
  final DateTime endDate;
  final TextEditingController maxCompletionsController;
  final List<OwnerMission> missions;
  final List<OwnerRewardTemplate> rewardTemplates;
  final Set<String> selectedMissionIds;
  final String? selectedRewardTemplateId;
  final bool isRepeatable;
  final bool hasCompletionLimit;
  final String? errorMessage;
  final VoidCallback? onClearError;
  final bool isSaving;
  final void Function(String missionId, bool selected) onMissionToggled;
  final ValueChanged<String?> onRewardTemplateChanged;
  final ValueChanged<bool> onRepeatableChanged;
  final ValueChanged<bool> onCompletionLimitChanged;
  final ValueChanged<DateTime> onStartDateChanged;
  final ValueChanged<DateTime> onEndDateChanged;
  final Future<bool> Function() onCreate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(
        title: 'Create Campaign',
        variant: AppTopBarVariant.modal,
      ),
      body: SafeArea(
        child: DashboardScroll(
          maxWidth: 640,
          child: OwnerSetupCard(
            title: 'Campaign',
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
                label: 'Campaign name',
                hint: 'e.g. Coffee club',
              ),
              const SizedBox(height: 16),
              const SectionHeader(title: 'Reward Template'),
              const SizedBox(height: 8),
              if (rewardTemplates.isEmpty)
                const EmptyStateView(
                  icon: Icons.card_giftcard_rounded,
                  title: 'No reward templates yet',
                )
              else
                SelectField<String>(
                  label: 'Reward template',
                  value: selectedRewardTemplateId,
                  options: rewardTemplates
                      .map(
                        (template) => SelectFieldOption(
                          value: template.id,
                          label: ownerRewardTemplateOptionLabel(template),
                        ),
                      )
                      .toList(),
                  onChanged: onRewardTemplateChanged,
                ),
              const SizedBox(height: 16),
              const SectionHeader(title: 'Included missions'),
              const SizedBox(height: 8),
              if (missions.isEmpty)
                const EmptyStateView(
                  icon: Icons.task_alt_rounded,
                  title: 'No missions available',
                )
              else
                ...missions.map(
                  (mission) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CheckboxRow(
                      title: mission.name,
                      subtitle: '${mission.pointValue} pts',
                      value: selectedMissionIds.contains(mission.id),
                      onChanged: (selected) =>
                          onMissionToggled(mission.id, selected ?? false),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              AppTextField(
                controller: thresholdController,
                label: 'Points needed',
                hint: 'e.g. 10',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              AppDateField(
                value: startDate,
                label: 'Start date',
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                onChanged: onStartDateChanged,
              ),
              const SizedBox(height: 12),
              AppDateField(
                value: endDate,
                label: 'End date',
                firstDate: startDate.add(const Duration(days: 1)),
                lastDate: DateTime(2100),
                onChanged: onEndDateChanged,
              ),
              const SizedBox(height: 12),
              ToggleRow(
                title: 'Repeatable campaign',
                value: isRepeatable,
                onChanged: onRepeatableChanged,
              ),
              if (isRepeatable) ...[
                const SizedBox(height: 8),
                ToggleRow(
                  title: 'Limit completions',
                  value: hasCompletionLimit,
                  onChanged: onCompletionLimitChanged,
                ),
                if (hasCompletionLimit) ...[
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: maxCompletionsController,
                    label: 'Completion limit',
                    hint: 'e.g. 2',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ],
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Create Campaign',
                icon: Icons.flag_rounded,
                isLoading: isSaving,
                onPressed:
                    isSaving ||
                        missions.isEmpty ||
                        rewardTemplates.isEmpty ||
                        selectedMissionIds.isEmpty ||
                        selectedRewardTemplateId == null
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
