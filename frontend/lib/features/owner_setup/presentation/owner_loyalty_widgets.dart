import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';
import '../domain/owner_setup_models.dart';
import 'owner_setup_shared_widgets.dart';

class OwnerMissionSetupCard extends StatelessWidget {
  const OwnerMissionSetupCard({
    super.key,
    required this.controller,
    required this.pointsController,
    required this.missions,
    required this.isSaving,
    required this.onCreate,
  });

  final TextEditingController controller;
  final TextEditingController pointsController;
  final List<OwnerMission> missions;
  final bool isSaving;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return OwnerSetupCard(
      title: 'Missions',
      subtitle: 'Define customer actions that can grant points.',
      children: [
        AppTextField(
          controller: controller,
          label: 'Mission name',
          hint: 'Buy Coffee',
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: pointsController,
          label: 'Point value',
          hint: '1',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Create Mission',
          icon: Icons.add_task_rounded,
          onPressed: isSaving ? null : onCreate,
          isLoading: isSaving,
        ),
        const SizedBox(height: 12),
        OwnerSimpleList(
          emptyTitle: 'No missions yet',
          emptyMessage: 'Created missions will appear here.',
          leadingIcon: Icons.task_alt_rounded,
          items: missions
              .map(
                (mission) => OwnerSimpleListItem(
                  title: mission.name,
                  subtitle: '${mission.pointValue} pts',
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class OwnerCampaignSetupCard extends StatelessWidget {
  const OwnerCampaignSetupCard({
    super.key,
    required this.controller,
    required this.thresholdController,
    required this.startDate,
    required this.endDate,
    required this.maxCompletionsController,
    required this.missions,
    required this.campaigns,
    required this.selectedMissionIds,
    required this.isRepeatable,
    required this.hasCompletionLimit,
    required this.isSaving,
    required this.onMissionToggled,
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
  final List<OwnerCampaign> campaigns;
  final Set<String> selectedMissionIds;
  final bool isRepeatable;
  final bool hasCompletionLimit;
  final bool isSaving;
  final void Function(String missionId, bool selected) onMissionToggled;
  final ValueChanged<bool> onRepeatableChanged;
  final ValueChanged<bool> onCompletionLimitChanged;
  final ValueChanged<DateTime> onStartDateChanged;
  final ValueChanged<DateTime> onEndDateChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return OwnerSetupCard(
      title: 'Campaigns',
      subtitle: 'Connect missions to a points threshold.',
      children: [
        AppTextField(
          controller: controller,
          label: 'Campaign name',
          hint: 'Coffee Reward',
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: thresholdController,
          label: 'Threshold points',
          hint: '10',
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
          CheckboxRow(
            title: 'Limit completions',
            value: hasCompletionLimit,
            onChanged: (selected) =>
                onCompletionLimitChanged(selected ?? false),
          ),
          if (hasCompletionLimit) ...[
            const SizedBox(height: 8),
            AppTextField(
              controller: maxCompletionsController,
              label: 'Max completions per customer',
              hint: '2',
              keyboardType: TextInputType.number,
            ),
          ],
        ],
        const SizedBox(height: 12),
        const SectionHeader(title: 'Included missions'),
        const SizedBox(height: 8),
        if (missions.isEmpty)
          const EmptyStateView(
            icon: Icons.task_alt_rounded,
            title: 'No missions available',
            message: 'Create a mission before creating a campaign.',
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
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Create Campaign',
          icon: Icons.flag_rounded,
          onPressed: isSaving || missions.isEmpty || selectedMissionIds.isEmpty
              ? null
              : onCreate,
          isLoading: isSaving,
        ),
        const SizedBox(height: 12),
        OwnerSimpleList(
          emptyTitle: 'No campaigns yet',
          emptyMessage: 'Created campaigns will appear here.',
          leadingIcon: Icons.campaign_rounded,
          items: campaigns
              .map(
                (campaign) => OwnerSimpleListItem(
                  title: campaign.name,
                  subtitle: _campaignSubtitle(campaign),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  String _campaignSubtitle(OwnerCampaign campaign) {
    final repeatableLabel = campaign.isRepeatable
        ? campaign.maxCompletionsPerCustomer == null
              ? 'repeatable · unlimited within dates'
              : 'repeatable · max ${campaign.maxCompletionsPerCustomer}'
        : 'non-repeatable';
    return '${campaign.thresholdPoints} pts · $repeatableLabel · ${campaign.status}';
  }
}

class OwnerRewardTemplateSetupCard extends StatelessWidget {
  const OwnerRewardTemplateSetupCard({
    super.key,
    required this.rewardNameController,
    required this.giftNameController,
    required this.validDaysController,
    required this.campaigns,
    required this.rewardTemplates,
    required this.selectedCampaignId,
    required this.isSaving,
    required this.onCampaignChanged,
    required this.onCreate,
  });

  final TextEditingController rewardNameController;
  final TextEditingController giftNameController;
  final TextEditingController validDaysController;
  final List<OwnerCampaign> campaigns;
  final List<OwnerRewardTemplate> rewardTemplates;
  final String? selectedCampaignId;
  final bool isSaving;
  final ValueChanged<String?> onCampaignChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return OwnerSetupCard(
      title: 'Reward Templates',
      subtitle: 'Create the gift reward issued after campaign completion.',
      children: [
        AppTextField(
          controller: rewardNameController,
          label: 'Reward name',
          hint: 'Free Coffee',
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: giftNameController,
          label: 'Gift name',
          hint: 'Free coffee',
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: validDaysController,
          label: 'Valid days',
          hint: '30',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        SelectField<String>(
          label: 'Campaign',
          value: selectedCampaignId,
          options: campaigns
              .map(
                (campaign) =>
                    SelectFieldOption(value: campaign.id, label: campaign.name),
              )
              .toList(),
          onChanged: onCampaignChanged,
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Create Gift Reward',
          icon: Icons.card_giftcard_rounded,
          onPressed: isSaving || campaigns.isEmpty ? null : onCreate,
          isLoading: isSaving,
        ),
        const SizedBox(height: 12),
        OwnerSimpleList(
          emptyTitle: 'No reward templates yet',
          emptyMessage: 'Created reward templates will appear here.',
          leadingIcon: Icons.card_giftcard_rounded,
          items: rewardTemplates
              .map(
                (template) => OwnerSimpleListItem(
                  title: template.name,
                  subtitle:
                      '${template.giftName ?? template.rewardType} · ${template.validDays} days',
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
