import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';
import '../domain/owner_setup_models.dart';
import 'owner_campaign_list_item.dart';
import 'owner_presenter.dart';
import 'owner_setup_shared_widgets.dart';

class OwnerCampaignListCard extends StatelessWidget {
  const OwnerCampaignListCard({
    super.key,
    required this.campaigns,
    required this.selectedTabIndex,
    required this.isSaving,
    required this.onPreviewEnd,
    required this.onEndCampaign,
  });

  final List<OwnerCampaign> campaigns;
  final int selectedTabIndex;
  final bool isSaving;
  final Future<int?> Function(OwnerCampaign campaign) onPreviewEnd;
  final Future<void> Function(
    OwnerCampaign campaign,
    int settlementCustomerCount,
  )
  onEndCampaign;

  @override
  Widget build(BuildContext context) {
    final visibleCampaigns = campaigns
        .where(
          (campaign) => selectedTabIndex == 0
              ? !ownerCampaignIsArchived(campaign)
              : ownerCampaignIsArchived(campaign),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (visibleCampaigns.isEmpty)
          EmptyStateView(
            icon: Icons.campaign_rounded,
            title: selectedTabIndex == 0
                ? 'Active campaigns will appear here after you create one.'
                : 'Ended and expired campaigns will appear here.',
          )
        else
          ...visibleCampaigns.map(
            (campaign) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OwnerCampaignListItem(
                campaign: campaign,
                showStatusBadge: campaign.displayStatus != 'Active',
                trailing: _CampaignStatusActions(
                  campaign: campaign,
                  isSaving: isSaving,
                  onPreviewEnd: onPreviewEnd,
                  onEndCampaign: onEndCampaign,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CampaignStatusActions extends StatelessWidget {
  const _CampaignStatusActions({
    required this.campaign,
    required this.isSaving,
    required this.onPreviewEnd,
    required this.onEndCampaign,
  });

  final OwnerCampaign campaign;
  final bool isSaving;
  final Future<int?> Function(OwnerCampaign campaign) onPreviewEnd;
  final Future<void> Function(
    OwnerCampaign campaign,
    int settlementCustomerCount,
  )
  onEndCampaign;

  @override
  Widget build(BuildContext context) {
    if (ownerCampaignIsArchived(campaign)) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'End campaign',
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          onPressed: isSaving ? null : () => _confirmEnd(context),
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
    );
  }

  Future<void> _confirmEnd(BuildContext context) async {
    final settlementCustomerCount = await onPreviewEnd(campaign);
    if (settlementCustomerCount == null || !context.mounted) {
      return;
    }
    final settlementMessage = settlementCustomerCount == 0
        ? 'No customers have incomplete progress. This campaign will move to Archive and staff will no longer register progress for it.'
        : '$settlementCustomerCount customer${settlementCustomerCount == 1 ? '' : 's'} with incomplete progress will receive this campaign reward. This campaign will then move to Archive and staff will no longer register progress for it.';
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'End campaign?',
      message: settlementMessage,
      confirmLabel: 'End campaign',
      tone: ConfirmTone.destructive,
    );
    if (!confirmed) {
      return;
    }
    await onEndCampaign(campaign, settlementCustomerCount);
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
