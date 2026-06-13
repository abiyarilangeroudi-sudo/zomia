import 'package:flutter/material.dart';

import '../../../app/brand/brand_colors.dart';
import '../../../app/ui/ui.dart';
import '../domain/staff_service_models.dart';

class StaffCustomerSummaryCard extends StatelessWidget {
  const StaffCustomerSummaryCard({
    super.key,
    required this.summary,
    required this.isLoading,
  });

  final StaffServiceSummary? summary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final summary = this.summary;
    return AppCard(
      child: isLoading
          ? const LoadingState(label: 'Loading customer')
          : summary == null
          ? const EmptyStateView(
              icon: Icons.person_search_rounded,
              title: 'No customer loaded',
              message: 'Scan a customer QR to start the service session.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: summary.customer.fullName,
                  subtitle: summary.customer.email,
                  trailing: const StatusBadge(
                    label: 'Loaded',
                    tone: BadgeTone.success,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MetricPill(
                      icon: Icons.stars_rounded,
                      label: '${summary.points} points',
                      color: BrandColors.orange,
                    ),
                    MetricPill(
                      icon: Icons.redeem_rounded,
                      label: '${summary.activeRewards.length} active rewards',
                      color: BrandColors.purple,
                    ),
                    MetricPill(
                      icon: Icons.history_rounded,
                      label: '${summary.recentActions.length} recent actions',
                      color: BrandColors.info,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class StaffMissionCard extends StatelessWidget {
  const StaffMissionCard({
    super.key,
    required this.missions,
    required this.quantities,
    required this.isLoading,
    required this.isEnabled,
    required this.selectedPoints,
    required this.onIncrement,
    required this.onDecrement,
    required this.onSubmit,
    required this.isSubmitting,
  });

  final List<StaffServiceMission> missions;
  final Map<String, int> quantities;
  final bool isLoading;
  final bool isEnabled;
  final int selectedPoints;
  final void Function(StaffServiceMission mission) onIncrement;
  final void Function(StaffServiceMission mission) onDecrement;
  final VoidCallback? onSubmit;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Register Action',
            trailing: MetricPill(
              icon: Icons.stars_rounded,
              label: '$selectedPoints pts',
              color: BrandColors.orange,
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const LoadingState(label: 'Loading missions')
          else if (missions.isEmpty)
            const EmptyStateView(
              icon: Icons.task_alt_rounded,
              title: 'No missions',
              message: 'No active missions are available for this business.',
            )
          else
            ...missions.map(
              (mission) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MissionRow(
                  title: mission.name,
                  subtitle: '${mission.pointValue} points each',
                  quantity: quantities[mission.id] ?? 0,
                  isEnabled: isEnabled,
                  onIncrement: () => onIncrement(mission),
                  onDecrement: () => onDecrement(mission),
                ),
              ),
            ),
          const SizedBox(height: 4),
          PrimaryButton(
            label: 'Register Action',
            icon: Icons.check_circle_rounded,
            onPressed: isEnabled && !isSubmitting ? onSubmit : null,
            isLoading: isSubmitting,
          ),
        ],
      ),
    );
  }
}

class StaffRewardsCard extends StatelessWidget {
  const StaffRewardsCard({
    super.key,
    required this.rewards,
    required this.rewardInUseId,
    required this.onUseReward,
  });

  final List<GeneratedReward> rewards;
  final String? rewardInUseId;
  final void Function(GeneratedReward reward) onUseReward;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Active Rewards',
            subtitle: 'Confirm before marking a reward as used.',
          ),
          const SizedBox(height: 12),
          if (rewards.isEmpty)
            const EmptyStateView(
              icon: Icons.redeem_rounded,
              title: 'No active rewards',
              message: 'Available rewards will appear after customer lookup.',
            )
          else
            ...rewards.map(
              (reward) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RewardCard(
                  title: reward.title,
                  subtitle: reward.displayValue,
                  expiresLabel: _formatRewardExpires(reward),
                  variant: RewardCardVariant.staffAction,
                  isLoading: rewardInUseId == reward.id,
                  onUse: () => onUseReward(reward),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class StaffRecentActionsCard extends StatelessWidget {
  const StaffRecentActionsCard({super.key, required this.actions});

  final List<StaffRecentAction> actions;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Recent Actions'),
          const SizedBox(height: 12),
          if (actions.isEmpty)
            const EmptyStateView(
              icon: Icons.history_rounded,
              title: 'No recent actions',
              message: 'Customer activity will appear after service starts.',
            )
          else
            ...actions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppListRow(
                  title: _formatActionType(action.actionType),
                  subtitle: _formatDateTime(action.occurredAt),
                  leadingIcon: Icons.receipt_long_rounded,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _formatRewardExpires(GeneratedReward reward) {
  return 'Valid until ${_formatDate(reward.expiresAt)}';
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final date =
      '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}

String _formatActionType(String value) {
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
