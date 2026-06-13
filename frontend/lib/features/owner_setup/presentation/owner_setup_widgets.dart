import 'package:flutter/material.dart';

import '../../../app/brand/brand_colors.dart';
import '../../../app/ui/ui.dart';
import '../../auth/domain/current_user.dart';
import '../domain/owner_setup_models.dart';

class OwnerHeader extends StatelessWidget {
  const OwnerHeader({
    super.key,
    required this.user,
    required this.selectedBusiness,
  });

  final CurrentUser user;
  final OwnerBusiness? selectedBusiness;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Owner Setup', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Signed in as ${user.fullName}'),
          if (selectedBusiness != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                MetricPill(
                  icon: Icons.storefront_rounded,
                  label: selectedBusiness!.name,
                  color: BrandColors.teal,
                ),
                MetricPill(
                  icon: Icons.payments_rounded,
                  label: selectedBusiness!.currencyCode,
                  color: BrandColors.orange,
                ),
                MetricPill(
                  icon: Icons.verified_rounded,
                  label: selectedBusiness!.status,
                  color: BrandColors.purple,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class OwnerProfileCard extends StatelessWidget {
  const OwnerProfileCard({
    super.key,
    required this.user,
    required this.selectedBusiness,
    required this.onSignOut,
  });

  final CurrentUser user;
  final OwnerBusiness? selectedBusiness;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Profile',
            subtitle: 'Owner context for the current setup session.',
          ),
          const SizedBox(height: 12),
          AppListRow(
            title: user.fullName,
            subtitle: user.email,
            leadingIcon: Icons.person_rounded,
          ),
          if (selectedBusiness != null) ...[
            const SizedBox(height: 12),
            AppListRow(
              title: selectedBusiness!.name,
              subtitle:
                  '${selectedBusiness!.currencyCode} · ${selectedBusiness!.status}',
              leadingIcon: Icons.storefront_rounded,
            ),
          ],
          const SizedBox(height: 16),
          SecondaryButton(
            label: 'Sign out',
            icon: Icons.logout_rounded,
            onPressed: onSignOut,
          ),
        ],
      ),
    );
  }
}

class OwnerRecentActionsDialog extends StatelessWidget {
  const OwnerRecentActionsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Staff Recent Actions',
        variant: AppTopBarVariant.modal,
      ),
      body: SafeArea(
        child: DashboardScroll(
          maxWidth: 760,
          child: AppCard(
            child: EmptyStateView(
              icon: Icons.history_rounded,
              title: 'No staff actions yet',
              message:
                  'Recent staff activity will appear here after the owner activity endpoint is available.',
              action: SecondaryButton(
                label: 'Close',
                icon: Icons.close_rounded,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OwnerBusinessPicker extends StatelessWidget {
  const OwnerBusinessPicker({
    super.key,
    required this.businesses,
    required this.selectedBusiness,
    required this.onChanged,
  });

  final List<OwnerBusiness> businesses;
  final OwnerBusiness? selectedBusiness;
  final ValueChanged<OwnerBusiness?> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Business'),
          const SizedBox(height: 12),
          SelectField<String>(
            label: 'Business',
            value: selectedBusiness?.id,
            options: businesses
                .map(
                  (business) => SelectFieldOption(
                    value: business.id,
                    label: business.name,
                  ),
                )
                .toList(),
            onChanged: (value) {
              onChanged(
                businesses
                    .where((business) => business.id == value)
                    .firstOrNull,
              );
            },
          ),
        ],
      ),
    );
  }
}

class OwnerStaffSetupCard extends StatelessWidget {
  const OwnerStaffSetupCard({
    super.key,
    required this.emailController,
    required this.fullNameController,
    required this.passwordController,
    required this.staffMembers,
    required this.isSaving,
    required this.onCreate,
  });

  final TextEditingController emailController;
  final TextEditingController fullNameController;
  final TextEditingController passwordController;
  final List<OwnerStaffMember> staffMembers;
  final bool isSaving;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return _SetupCard(
      title: 'Staff',
      subtitle: 'Create staff access for the selected business.',
      children: [
        AppTextField(
          controller: emailController,
          label: 'Staff email',
          hint: 'staff@example.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: fullNameController,
          label: 'Staff name',
          hint: 'Staff One',
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: passwordController,
          label: 'Temporary password',
          obscureText: true,
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Create Staff',
          icon: Icons.person_add_alt_1_rounded,
          onPressed: isSaving ? null : onCreate,
          isLoading: isSaving,
        ),
        const SizedBox(height: 12),
        _SimpleList(
          emptyTitle: 'No staff yet',
          emptyMessage: 'Created staff users will appear here.',
          leadingIcon: Icons.person_rounded,
          items: staffMembers
              .map(
                (staffMember) => _SimpleListItem(
                  title: staffMember.user.fullName,
                  subtitle: staffMember.user.email,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

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
    return _SetupCard(
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
        _SimpleList(
          emptyTitle: 'No missions yet',
          emptyMessage: 'Created missions will appear here.',
          leadingIcon: Icons.task_alt_rounded,
          items: missions
              .map(
                (mission) => _SimpleListItem(
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
    required this.missions,
    required this.campaigns,
    required this.selectedMissionIds,
    required this.isSaving,
    required this.onMissionToggled,
    required this.onCreate,
  });

  final TextEditingController controller;
  final TextEditingController thresholdController;
  final List<OwnerMission> missions;
  final List<OwnerCampaign> campaigns;
  final Set<String> selectedMissionIds;
  final bool isSaving;
  final void Function(String missionId, bool selected) onMissionToggled;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return _SetupCard(
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
        _SimpleList(
          emptyTitle: 'No campaigns yet',
          emptyMessage: 'Created campaigns will appear here.',
          leadingIcon: Icons.campaign_rounded,
          items: campaigns
              .map(
                (campaign) => _SimpleListItem(
                  title: campaign.name,
                  subtitle:
                      '${campaign.thresholdPoints} pts · ${campaign.status}',
                ),
              )
              .toList(),
        ),
      ],
    );
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
    return _SetupCard(
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
        _SimpleList(
          emptyTitle: 'No reward templates yet',
          emptyMessage: 'Created reward templates will appear here.',
          leadingIcon: Icons.card_giftcard_rounded,
          items: rewardTemplates
              .map(
                (template) => _SimpleListItem(
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

class _SetupCard extends StatelessWidget {
  const _SetupCard({
    required this.title,
    this.subtitle,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: title, subtitle: subtitle),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _SimpleList extends StatelessWidget {
  const _SimpleList({
    required this.emptyTitle,
    required this.emptyMessage,
    required this.items,
    required this.leadingIcon,
  });

  final String emptyTitle;
  final String emptyMessage;
  final List<_SimpleListItem> items;
  final IconData leadingIcon;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyStateView(
        icon: leadingIcon,
        title: emptyTitle,
        message: emptyMessage,
      );
    }

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppListRow(
                title: item.title,
                subtitle: item.subtitle,
                leadingIcon: leadingIcon,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SimpleListItem {
  const _SimpleListItem({required this.title, this.subtitle});

  final String title;
  final String? subtitle;
}
