import 'package:flutter/material.dart';

import '../../../app/brand/brand_colors.dart';
import '../../../app/ui/ui.dart';
import '../domain/staff_service_models.dart';
import 'staff_service_presenter.dart';

class StaffCustomerSummaryCard extends StatelessWidget {
  const StaffCustomerSummaryCard({
    super.key,
    required this.summary,
    required this.isLoading,
    required this.isConfirmed,
    required this.onConfirm,
    required this.onReject,
  });

  final StaffServiceSummary? summary;
  final bool isLoading;
  final bool isConfirmed;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

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
                  trailing: StatusBadge(
                    label: isConfirmed ? 'Confirmed' : 'Confirm',
                    tone: isConfirmed ? BadgeTone.success : BadgeTone.info,
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
                if (!isConfirmed) ...[
                  const SizedBox(height: 16),
                  _StaffCustomerActions(
                    onReject: onReject,
                    onConfirm: onConfirm,
                  ),
                ],
              ],
            ),
    );
  }
}

class _StaffCustomerActions extends StatelessWidget {
  const _StaffCustomerActions({
    required this.onReject,
    required this.onConfirm,
  });

  final VoidCallback onReject;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rejectButton = SecondaryButton(
          label: 'Reject',
          icon: Icons.close_rounded,
          onPressed: onReject,
        );
        final confirmButton = PrimaryButton(
          label: 'Confirm',
          icon: Icons.check_rounded,
          onPressed: onConfirm,
        );

        if (constraints.maxWidth < 340) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [rejectButton, const SizedBox(height: 8), confirmButton],
          );
        }

        return Row(
          children: [
            Expanded(child: rejectButton),
            const SizedBox(width: 12),
            Expanded(child: confirmButton),
          ],
        );
      },
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
                  expiresLabel: rewardExpiresLabel(reward),
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
  const StaffRecentActionsCard({
    super.key,
    required this.actions,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  final List<StaffRecentAction> actions;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Staff recent actions'),
          const SizedBox(height: 12),
          if (isLoading)
            const LoadingState(label: 'Loading staff actions')
          else if (errorMessage != null) ...[
            InlineBanner(message: errorMessage!, tone: BannerTone.error),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Retry',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
            ],
          ] else if (actions.isEmpty)
            const EmptyStateView(
              icon: Icons.history_rounded,
              title: 'No staff actions yet',
              message:
                  'Staff activity will appear after actions are registered.',
            )
          else
            ...actions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppListRow(
                  title: action.summary,
                  subtitle:
                      '${action.customerName} · ${formatStaffDateTime(action.occurredAt)}',
                  leadingIcon: Icons.history_rounded,
                  trailing: StatusBadge(
                    label: action.pointsGranted > 0
                        ? '+${action.pointsGranted} pts'
                        : formatStaffActionType(action.actionType),
                    tone: action.pointsGranted > 0
                        ? BadgeTone.success
                        : BadgeTone.neutral,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
