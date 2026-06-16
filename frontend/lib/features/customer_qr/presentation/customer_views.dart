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
  });

  final CurrentUser user;
  final CustomerStatus? status;
  final List<CustomerCampaignProgress> campaignProgresses;

  @override
  Widget build(BuildContext context) {
    final activeRewardsCount = status?.activeRewardsCount ?? 0;
    final activeCampaignCount = customerActiveCampaignCount(campaignProgresses);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, ${user.fullName}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  MetricPill(
                    icon: Icons.campaign_rounded,
                    label: '$activeCampaignCount active campaigns',
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
        const SizedBox(height: 12),
        AppCard(
          child: EmptyStateView(
            icon: Icons.qr_code_rounded,
            title: activeCampaignCount == 0 && activeRewardsCount == 0
                ? 'Ready to start'
                : 'Ready for your next visit',
            message:
                'Use the QR button when staff asks to scan your customer account.',
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
    required this.selectedTabIndex,
    required this.onTabChanged,
  });

  final List<CustomerCampaignProgress> campaignProgresses;
  final bool isLoadingStatus;
  final String? statusError;
  final int selectedTabIndex;
  final ValueChanged<int> onTabChanged;

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
        SegmentedTabs(
          items: const ['All', 'Archive'],
          selectedIndex: selectedTabIndex,
          onChanged: onTabChanged,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (selectedTabIndex == 1)
                const AppCard(
                  child: EmptyStateView(
                    icon: Icons.archive_outlined,
                    title: 'No archived campaigns',
                    message: 'Archived campaigns will appear here later.',
                  ),
                )
              else
                ...campaignProgresses.map(
                  (progress) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ProgressCard(
                      title: progress.campaignName,
                      subtitle: progress.businessName,
                      value: progress.progressRatio,
                      label: progress.displayLabel,
                      timeRangeLabel: customerFormatDateRange(
                        progress.startsAt,
                        progress.endsAt,
                      ),
                      badgeLabel: progress.badgeLabel,
                      badgeTone: customerBadgeTone(progress.badgeTone),
                    ),
                  ),
                ),
            ],
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
    required this.selectedTabIndex,
    required this.onTabChanged,
  });

  final CustomerStatus? status;
  final bool isLoadingStatus;
  final String? statusError;
  final int selectedTabIndex;
  final ValueChanged<int> onTabChanged;

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
        SegmentedTabs(
          items: const ['All', 'Archive'],
          selectedIndex: selectedTabIndex,
          onChanged: onTabChanged,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (selectedTabIndex == 1)
                const AppCard(
                  child: EmptyStateView(
                    icon: Icons.archive_outlined,
                    title: 'No archived rewards',
                    message: 'Archived rewards will appear here later.',
                  ),
                )
              else
                ...rewards.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RewardCard(
                      title: entry.reward.title,
                      businessName: entry.businessName,
                      subtitle: entry.reward.displayValue,
                      expiresLabel: customerRewardExpiresLabel(entry.reward),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<CustomerRewardEntry> _activeRewards() =>
      customerActiveRewardEntries(status);
}

class CustomerProfileDialog extends StatelessWidget {
  const CustomerProfileDialog({
    super.key,
    required this.user,
    required this.onUpdateName,
  });

  final CurrentUser user;
  final Future<void> Function(String fullName) onUpdateName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(
        title: 'Profile',
        variant: AppTopBarVariant.modal,
      ),
      body: SafeArea(
        child: DashboardScroll(
          maxWidth: 640,
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppListRow(
                  title: user.fullName,
                  subtitle: user.email,
                  leadingIcon: Icons.person_rounded,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Edit Profile',
                  icon: Icons.edit_rounded,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      fullscreenDialog: true,
                      builder: (context) => CustomerEditProfileDialog(
                        user: user,
                        onUpdateName: onUpdateName,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomerEditProfileDialog extends StatefulWidget {
  const CustomerEditProfileDialog({
    super.key,
    required this.user,
    required this.onUpdateName,
  });

  final CurrentUser user;
  final Future<void> Function(String fullName) onUpdateName;

  @override
  State<CustomerEditProfileDialog> createState() =>
      _CustomerEditProfileDialogState();
}

class _CustomerEditProfileDialogState extends State<CustomerEditProfileDialog> {
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
  void didUpdateWidget(covariant CustomerEditProfileDialog oldWidget) {
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
    return Scaffold(
      appBar: const AppTopBar(
        title: 'Edit Profile',
        variant: AppTopBarVariant.modal,
      ),
      body: SafeArea(
        child: DashboardScroll(
          maxWidth: 640,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                InlineBanner(message: _error!, tone: BannerTone.error),
              if (_success != null)
                InlineBanner(message: _success!, tone: BannerTone.success),
              if (_error != null || _success != null)
                const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
