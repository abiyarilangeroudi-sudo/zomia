import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';
import '../../auth/domain/current_user.dart';
import '../domain/customer_status.dart';
import 'customer_presenter.dart';

class CustomerCampaignView extends StatelessWidget {
  const CustomerCampaignView({
    super.key,
    required this.campaignProgresses,
    required this.isLoadingStatus,
    required this.statusError,
    required this.onClearStatusError,
    required this.selectedTabIndex,
    required this.onTabChanged,
  });

  final List<CustomerCampaignProgress> campaignProgresses;
  final bool isLoadingStatus;
  final String? statusError;
  final VoidCallback onClearStatusError;
  final int selectedTabIndex;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    if (isLoadingStatus) {
      return const AppCard(child: LoadingState(label: 'Loading campaigns'));
    }
    if (statusError != null) {
      return InlineBanner(
        message: statusError!,
        tone: BannerTone.error,
        onClose: onClearStatusError,
      );
    }
    final visibleProgresses = selectedTabIndex == 1
        ? customerArchivedCampaignProgresses(campaignProgresses)
        : customerActiveCampaignProgresses(campaignProgresses);
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
              if (visibleProgresses.isEmpty)
                const AppCard(
                  child: EmptyStateView(
                    icon: Icons.campaign_outlined,
                    title: 'No campaign progress',
                    message:
                        'Your progress will appear here after a matching visit.',
                  ),
                )
              else
                ...visibleProgresses.map(
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
    required this.onClearStatusError,
    required this.selectedTabIndex,
    required this.onTabChanged,
  });

  final CustomerStatus? status;
  final bool isLoadingStatus;
  final String? statusError;
  final VoidCallback onClearStatusError;
  final int selectedTabIndex;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    if (isLoadingStatus) {
      return const AppCard(child: LoadingState(label: 'Loading rewards'));
    }
    if (statusError != null) {
      return InlineBanner(
        message: statusError!,
        tone: BannerTone.error,
        onClose: onClearStatusError,
      );
    }
    final rewards = _visibleRewards();
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
              if (rewards.isEmpty)
                AppCard(
                  child: EmptyStateView(
                    icon: Icons.archive_outlined,
                    title: 'No rewards here',
                    message: selectedTabIndex == 1
                        ? 'Used and expired rewards will appear here.'
                        : 'Rewards ready for staff to use will appear here.',
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
                      badgeLabel: customerRewardBadgeLabel(entry.reward),
                      badgeTone: customerRewardBadgeTone(entry.reward),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<CustomerRewardEntry> _visibleRewards() => selectedTabIndex == 1
      ? customerArchivedRewardEntries(status)
      : customerActiveRewardEntries(status);
}

class CustomerProfileDialog extends StatefulWidget {
  const CustomerProfileDialog({
    super.key,
    required this.user,
    required this.onUpdateName,
  });

  final CurrentUser user;
  final Future<void> Function(String fullName) onUpdateName;

  @override
  State<CustomerProfileDialog> createState() => _CustomerProfileDialogState();
}

class _CustomerProfileDialogState extends State<CustomerProfileDialog> {
  late String _displayName;

  @override
  void initState() {
    super.initState();
    _displayName = widget.user.fullName;
  }

  @override
  void didUpdateWidget(covariant CustomerProfileDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.fullName != widget.user.fullName) {
      _displayName = widget.user.fullName;
    }
  }

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
                  title: _displayName,
                  subtitle: widget.user.email,
                  leadingIcon: Icons.person_rounded,
                  trailing: IconButton(
                    tooltip: 'Edit profile',
                    icon: const Icon(Icons.edit_rounded),
                    onPressed: _openEditProfile,
                  ),
                  onTap: _openEditProfile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openEditProfile() async {
    final updatedName = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (context) => CustomerEditProfileDialog(
          user: widget.user,
          currentName: _displayName,
          onUpdateName: widget.onUpdateName,
        ),
      ),
    );
    if (!mounted || updatedName == null) {
      return;
    }
    setState(() => _displayName = updatedName);
  }
}

class CustomerEditProfileDialog extends StatefulWidget {
  const CustomerEditProfileDialog({
    super.key,
    required this.user,
    required this.currentName,
    required this.onUpdateName,
  });

  final CurrentUser user;
  final String currentName;
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
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void didUpdateWidget(covariant CustomerEditProfileDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentName != widget.currentName &&
        _nameController.text != widget.currentName) {
      _nameController.text = widget.currentName;
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
        variant: AppTopBarVariant.service,
      ),
      body: SafeArea(
        child: DashboardScroll(
          maxWidth: 640,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                InlineBanner(
                  message: _error!,
                  tone: BannerTone.error,
                  onClose: () => setState(() => _error = null),
                ),
              if (_success != null)
                InlineBanner(
                  message: _success!,
                  tone: BannerTone.success,
                  onClose: () => setState(() => _success = null),
                ),
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
    if (nextName == widget.currentName) {
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
      Navigator.of(context).pop(nextName);
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
