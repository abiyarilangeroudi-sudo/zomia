import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';
import '../domain/owner_setup_models.dart';
import 'owner_presenter.dart';
import 'owner_setup_shared_widgets.dart';

class OwnerCampaignListCard extends StatelessWidget {
  const OwnerCampaignListCard({super.key, required this.campaigns});

  final List<OwnerCampaign> campaigns;

  @override
  Widget build(BuildContext context) {
    return OwnerSetupCard(
      title: 'Campaigns',
      children: [
        OwnerSimpleList(
          emptyTitle: 'No campaigns yet',
          emptyMessage: 'Created campaigns will appear here.',
          leadingIcon: Icons.campaign_rounded,
          items: campaigns
              .map(
                (campaign) => OwnerSimpleListItem(
                  title: campaign.name,
                  subtitle: ownerCampaignSubtitle(campaign),
                ),
              )
              .toList(),
        ),
      ],
    );
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
    required this.selectedMissionIds,
    required this.isRepeatable,
    required this.hasCompletionLimit,
    this.errorMessage,
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
  final Set<String> selectedMissionIds;
  final bool isRepeatable;
  final bool hasCompletionLimit;
  final String? errorMessage;
  final bool isSaving;
  final void Function(String missionId, bool selected) onMissionToggled;
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
                InlineBanner(message: errorMessage!, tone: BannerTone.error),
                const SizedBox(height: 12),
              ],
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
                ToggleRow(
                  title: 'Limit completions',
                  value: hasCompletionLimit,
                  onChanged: onCompletionLimitChanged,
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
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Create Campaign',
                icon: Icons.flag_rounded,
                isLoading: isSaving,
                onPressed:
                    isSaving || missions.isEmpty || selectedMissionIds.isEmpty
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
