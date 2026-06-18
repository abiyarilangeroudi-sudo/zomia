import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
                        'Progress appears after staff registers matching actions.',
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
                const AppCard(
                  child: EmptyStateView(
                    icon: Icons.archive_outlined,
                    title: 'No rewards here',
                    message: 'Rewards move between All and Archive by status.',
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

class CustomerSettingsDialog extends StatelessWidget {
  const CustomerSettingsDialog({
    super.key,
    required this.onChangePassword,
    required this.onStartEmailChange,
    required this.onVerifyEmailChange,
  });

  final Future<void> Function({
    required String currentPassword,
    required String newPassword,
  })
  onChangePassword;
  final Future<void> Function({
    required String newEmail,
    required String currentPassword,
  })
  onStartEmailChange;
  final Future<void> Function({required String newEmail, required String code})
  onVerifyEmailChange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(
        title: 'Settings',
        variant: AppTopBarVariant.modal,
      ),
      body: SafeArea(
        child: DashboardScroll(
          maxWidth: 640,
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Account', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                AppListRow(
                  title: 'Change Password',
                  leadingIcon: Icons.lock_reset_rounded,
                  onTap: () => _openChangePasswordDialog(context),
                ),
                const SizedBox(height: 12),
                AppListRow(
                  title: 'Change Email',
                  leadingIcon: Icons.alternate_email_rounded,
                  onTap: () => _openChangeEmailDialog(context),
                ),
                const SizedBox(height: 12),
                AppListRow(
                  title: 'Remove Account',
                  leadingIcon: Icons.person_remove_alt_1_rounded,
                  onTap: () =>
                      _openPlannedDialog(context, title: 'Remove Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openChangePasswordDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) =>
            CustomerChangePasswordDialog(onChangePassword: onChangePassword),
      ),
    );
  }

  void _openChangeEmailDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => CustomerChangeEmailDialog(
          onStartEmailChange: onStartEmailChange,
          onVerifyEmailChange: onVerifyEmailChange,
        ),
      ),
    );
  }

  void _openPlannedDialog(BuildContext context, {required String title}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) =>
            AppDrawerInfoDialog(title: title, message: 'Planned.'),
      ),
    );
  }
}

class CustomerChangePasswordDialog extends StatefulWidget {
  const CustomerChangePasswordDialog({
    super.key,
    required this.onChangePassword,
  });

  final Future<void> Function({
    required String currentPassword,
    required String newPassword,
  })
  onChangePassword;

  @override
  State<CustomerChangePasswordDialog> createState() =>
      _CustomerChangePasswordDialogState();
}

class _CustomerChangePasswordDialogState
    extends State<CustomerChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _error;
  bool _isSaving = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(
        title: 'Change Password',
        variant: AppTopBarVariant.service,
      ),
      body: SafeArea(
        child: DashboardScroll(
          maxWidth: 640,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                InlineBanner(message: _error!, tone: BannerTone.error),
                const SizedBox(height: 16),
              ],
              AppCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: _currentPasswordController,
                        label: 'Current Password',
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if ((value ?? '').isEmpty) {
                            return 'Current password is required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _newPasswordController,
                        label: 'New Password',
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if ((value ?? '').length < 8) {
                            return 'Password must be at least 8 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match.';
                          }
                          return null;
                        },
                        onSubmitted: (_) => _save(),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Save password',
                        icon: Icons.check_rounded,
                        isLoading: _isSaving,
                        onPressed: _isSaving ? null : _save,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.onChangePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (!mounted) {
        return;
      }
      navigator.popUntil((route) => route.isFirst);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Password changed. Please sign in again.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class CustomerChangeEmailDialog extends StatefulWidget {
  const CustomerChangeEmailDialog({
    super.key,
    required this.onStartEmailChange,
    required this.onVerifyEmailChange,
  });

  final Future<void> Function({
    required String newEmail,
    required String currentPassword,
  })
  onStartEmailChange;
  final Future<void> Function({required String newEmail, required String code})
  onVerifyEmailChange;

  @override
  State<CustomerChangeEmailDialog> createState() =>
      _CustomerChangeEmailDialogState();
}

class _CustomerChangeEmailDialogState extends State<CustomerChangeEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  final _newEmailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _codeController = TextEditingController();
  String? _pendingEmail;
  String? _error;
  bool _isSaving = false;

  @override
  void dispose() {
    _newEmailController.dispose();
    _currentPasswordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(
        title: 'Change Email',
        variant: AppTopBarVariant.service,
      ),
      body: SafeArea(
        child: DashboardScroll(
          maxWidth: 640,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                InlineBanner(message: _error!, tone: BannerTone.error),
                const SizedBox(height: 16),
              ],
              AppCard(
                child: Form(
                  key: _formKey,
                  child: _pendingEmail == null
                      ? _buildStartForm()
                      : _buildVerifyForm(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _newEmailController,
          label: 'New Email',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: (value) {
            final email = value?.trim() ?? '';
            if (email.isEmpty) {
              return 'Email is required.';
            }
            if (!email.contains('@')) {
              return 'Enter a valid email address.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _currentPasswordController,
          label: 'Current Password',
          obscureText: true,
          textInputAction: TextInputAction.done,
          validator: (value) {
            if ((value ?? '').isEmpty) {
              return 'Current password is required.';
            }
            return null;
          },
          onSubmitted: (_) => _startEmailChange(),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Send code',
          icon: Icons.mark_email_unread_rounded,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _startEmailChange,
        ),
      ],
    );
  }

  Widget _buildVerifyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InlineBanner(
          message: 'Code sent to $_pendingEmail.',
          tone: BannerTone.success,
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _codeController,
          label: 'Verification code',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          maxLength: 6,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          validator: (value) {
            final code = value?.trim() ?? '';
            if (!RegExp(r'^\d{6}$').hasMatch(code)) {
              return 'Enter the 6-digit code.';
            }
            return null;
          },
          onSubmitted: (_) => _verifyEmailChange(),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Verify email',
          icon: Icons.verified_rounded,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _verifyEmailChange,
        ),
      ],
    );
  }

  Future<void> _startEmailChange() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final newEmail = _newEmailController.text.trim();
    try {
      await widget.onStartEmailChange(
        newEmail: newEmail,
        currentPassword: _currentPasswordController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() => _pendingEmail = newEmail);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _verifyEmailChange() async {
    if (!_formKey.currentState!.validate() || _pendingEmail == null) {
      return;
    }
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.onVerifyEmailChange(
        newEmail: _pendingEmail!,
        code: _codeController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Email changed.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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
