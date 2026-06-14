import 'package:flutter/material.dart';

import '../../../app/brand/brand_colors.dart';
import '../../../app/ui/ui.dart';
import '../../auth/domain/current_user.dart';
import '../domain/customer_status.dart';

class CustomerHomeView extends StatelessWidget {
  const CustomerHomeView({
    super.key,
    required this.user,
    required this.status,
    required this.campaignProgresses,
    required this.isLoadingStatus,
    required this.statusError,
    required this.onRefreshStatus,
  });

  final CurrentUser user;
  final CustomerStatus? status;
  final List<CustomerCampaignProgress> campaignProgresses;
  final bool isLoadingStatus;
  final String? statusError;
  final VoidCallback onRefreshStatus;

  @override
  Widget build(BuildContext context) {
    final activeRewardsCount = status?.activeRewardsCount ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${user.fullName}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(user.email),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  MetricPill(
                    icon: Icons.campaign_rounded,
                    label: '${campaignProgresses.length} campaigns',
                    color: BrandColors.teal,
                  ),
                  MetricPill(
                    icon: Icons.card_giftcard_rounded,
                    label: '$activeRewardsCount active rewards',
                    color: BrandColors.purple,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (isLoadingStatus)
          const AppCard(child: LoadingState(label: 'Loading status'))
        else if (statusError != null)
          InlineBanner(message: statusError!, tone: BannerTone.error)
        else if (campaignProgresses.isEmpty && activeRewardsCount == 0)
          const AppCard(
            child: EmptyStateView(
              icon: Icons.loyalty_outlined,
              title: 'No loyalty activity yet',
              message: 'Campaign progress and active rewards will appear here.',
            ),
          )
        else
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: 'Current Status',
                  subtitle: 'Refresh after staff registers an action.',
                  trailing: IconButton(
                    tooltip: 'Refresh status',
                    onPressed: isLoadingStatus ? null : onRefreshStatus,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                if (campaignProgresses.isNotEmpty)
                  ProgressCard(
                    title: campaignProgresses.first.campaignName,
                    subtitle: campaignProgresses.first.businessName,
                    value: campaignProgresses.first.progressRatio,
                    label: campaignProgresses.first.displayLabel,
                    badgeLabel: campaignProgresses.first.badgeLabel,
                    badgeTone: customerBadgeTone(
                      campaignProgresses.first.badgeTone,
                    ),
                  ),
                if (activeRewardsCount > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    '$activeRewardsCount active rewards available',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class CustomerCampaignView extends StatelessWidget {
  const CustomerCampaignView({
    super.key,
    required this.campaignProgresses,
    required this.isLoadingStatus,
    required this.statusError,
  });

  final List<CustomerCampaignProgress> campaignProgresses;
  final bool isLoadingStatus;
  final String? statusError;

  @override
  Widget build(BuildContext context) {
    if (isLoadingStatus) {
      return const AppCard(child: LoadingState(label: 'Loading campaigns'));
    }
    if (statusError != null) {
      return InlineBanner(message: statusError!, tone: BannerTone.error);
    }
    if (campaignProgresses.isEmpty) {
      return const AppCard(
        child: EmptyStateView(
          icon: Icons.campaign_outlined,
          title: 'No campaign progress',
          message: 'Progress appears after staff registers matching actions.',
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Campaign Progress',
          subtitle: 'Only campaign-based progress is shown here.',
        ),
        const SizedBox(height: 12),
        ...campaignProgresses.map(
          (progress) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ProgressCard(
              title: progress.campaignName,
              subtitle: progress.businessName,
              value: progress.progressRatio,
              label: progress.displayLabel,
              badgeLabel: progress.badgeLabel,
              badgeTone: customerBadgeTone(progress.badgeTone),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomerRewardView extends StatelessWidget {
  const CustomerRewardView({
    super.key,
    required this.status,
    required this.isLoadingStatus,
    required this.statusError,
  });

  final CustomerStatus? status;
  final bool isLoadingStatus;
  final String? statusError;

  @override
  Widget build(BuildContext context) {
    if (isLoadingStatus) {
      return const AppCard(child: LoadingState(label: 'Loading rewards'));
    }
    if (statusError != null) {
      return InlineBanner(message: statusError!, tone: BannerTone.error);
    }
    final rewards = _activeRewards();
    if (rewards.isEmpty) {
      return const AppCard(
        child: EmptyStateView(
          icon: Icons.card_giftcard_outlined,
          title: 'No active rewards',
          message: 'Rewards will appear after campaign completion.',
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Active Rewards',
          subtitle: 'Show available rewards to staff during service.',
        ),
        const SizedBox(height: 12),
        ...rewards.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RewardCard(
              title: entry.reward.title,
              businessName: entry.businessName,
              subtitle: entry.reward.displayValue,
              expiresLabel:
                  'Expires ${customerFormatDateTime(entry.reward.expiresAt)}',
            ),
          ),
        ),
      ],
    );
  }

  List<_CustomerRewardEntry> _activeRewards() {
    final status = this.status;
    if (status == null) {
      return const [];
    }
    return [
      for (final business in status.businesses)
        for (final reward in business.activeRewards)
          _CustomerRewardEntry(
            businessName: business.businessName,
            reward: reward,
          ),
    ];
  }
}

class CustomerProfileView extends StatefulWidget {
  const CustomerProfileView({
    super.key,
    required this.user,
    required this.onUpdateName,
    required this.onSignOut,
  });

  final CurrentUser user;
  final Future<void> Function(String fullName) onUpdateName;
  final VoidCallback onSignOut;

  @override
  State<CustomerProfileView> createState() => _CustomerProfileViewState();
}

class _CustomerProfileViewState extends State<CustomerProfileView> {
  late final TextEditingController _nameController;
  String? _error;
  String? _success;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName);
  }

  @override
  void didUpdateWidget(covariant CustomerProfileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.fullName != widget.user.fullName &&
        _nameController.text != widget.user.fullName) {
      _nameController.text = widget.user.fullName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          InlineBanner(message: _error!, tone: BannerTone.error),
        if (_success != null)
          InlineBanner(message: _success!, tone: BannerTone.success),
        if (_error != null || _success != null) const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(
                title: 'Profile',
                subtitle: 'Customer account for this MVP session.',
              ),
              const SizedBox(height: 12),
              AppListRow(
                title: widget.user.fullName,
                subtitle: widget.user.email,
                leadingIcon: Icons.person_rounded,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _nameController,
                label: 'Name',
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _saveName(),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Save profile',
                icon: Icons.check_rounded,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _saveName,
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Sign out',
                icon: Icons.logout_rounded,
                onPressed: widget.onSignOut,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveName() async {
    final nextName = _nameController.text.trim();
    if (nextName.length < 2) {
      setState(() {
        _error = 'Name must be at least 2 characters.';
        _success = null;
      });
      return;
    }
    if (nextName == widget.user.fullName) {
      setState(() {
        _error = null;
        _success = 'Profile is already up to date.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
      _success = null;
    });
    try {
      await widget.onUpdateName(nextName);
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
        _success = 'Profile updated.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
        _error = error.toString();
      });
    }
  }
}

class _CustomerRewardEntry {
  const _CustomerRewardEntry({
    required this.businessName,
    required this.reward,
  });

  final String businessName;
  final CustomerReward reward;
}

BadgeTone customerBadgeTone(String value) {
  return switch (value) {
    'success' => BadgeTone.success,
    'warning' => BadgeTone.warning,
    'neutral' => BadgeTone.neutral,
    _ => BadgeTone.info,
  };
}

String customerFormatDateTime(DateTime value) {
  final local = value.toLocal();
  final date =
      '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}
