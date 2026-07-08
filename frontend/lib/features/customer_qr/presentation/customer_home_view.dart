import 'package:flutter/material.dart';

import '../../../app/brand/brand_colors.dart';
import '../../../app/ui/ui.dart';
import '../../auth/domain/current_user.dart';
import '../domain/customer_status.dart';
import 'customer_presenter.dart';

class CustomerHomeView extends StatelessWidget {
  const CustomerHomeView({
    super.key,
    required this.user,
    required this.status,
    required this.campaignProgresses,
    required this.onShowQr,
  });

  final CurrentUser user;
  final CustomerStatus? status;
  final List<CustomerCampaignProgress> campaignProgresses;
  final VoidCallback onShowQr;

  @override
  Widget build(BuildContext context) {
    final stepsState = customerLoyaltyStepsState(
      status: status,
      campaignProgresses: campaignProgresses,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CustomerQrPromptCard(name: user.fullName, onShowQr: onShowQr),
        const SizedBox(height: 12),
        CustomerLoyaltyStepsCard(state: stepsState),
      ],
    );
  }
}

class _CustomerQrPromptCard extends StatelessWidget {
  const _CustomerQrPromptCard({required this.name, required this.onShowQr});

  final String name;
  final VoidCallback onShowQr;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Hi, $name', style: textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text('Ready for your next visit', style: textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Show your QR code to staff when you visit a participating business.',
            style: textTheme.bodyMedium?.copyWith(
              color: BrandColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Show QR',
            icon: Icons.qr_code_rounded,
            onPressed: onShowQr,
          ),
        ],
      ),
    );
  }
}

class CustomerLoyaltyStepsCard extends StatelessWidget {
  const CustomerLoyaltyStepsCard({super.key, required this.state});

  final CustomerLoyaltyStepsState state;

  @override
  Widget build(BuildContext context) {
    final nextStep = state.nextStep;

    return AppCard(
      child: state.isComplete
          ? const _CustomerLoyaltyFlowComplete()
          : _CustomerNextStepSummary(state: state, step: nextStep!),
    );
  }
}

class _CustomerNextStepSummary extends StatelessWidget {
  const _CustomerNextStepSummary({required this.state, required this.step});

  final CustomerLoyaltyStepsState state;
  final CustomerLoyaltyStep step;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Next step',
          subtitle: '${state.completedCount} of ${state.taskCount} steps done',
          trailing: const StatusBadge(label: 'Next', tone: BadgeTone.warning),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: BrandColors.teal.withValues(alpha: 0.06),
            border: Border.all(color: BrandColors.teal.withValues(alpha: 0.18)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title, style: textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  step.subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: BrandColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomerLoyaltyFlowComplete extends StatelessWidget {
  const _CustomerLoyaltyFlowComplete();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.teal.withValues(alpha: 0.08),
        border: Border.all(color: BrandColors.teal.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: BrandColors.teal,
              foregroundColor: Colors.white,
              child: Icon(Icons.verified_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'First loyalty flow complete',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Keep showing your QR on each visit to earn more rewards.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: BrandColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const StatusBadge(label: 'Done', tone: BadgeTone.success),
          ],
        ),
      ),
    );
  }
}
