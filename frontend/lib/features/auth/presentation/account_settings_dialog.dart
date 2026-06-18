import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/ui/ui.dart';

class AccountSettingsDialog extends StatelessWidget {
  const AccountSettingsDialog({
    super.key,
    required this.onChangePassword,
    this.onStartEmailChange,
    this.onVerifyEmailChange,
    this.onRemoveAccount,
  });

  final Future<void> Function({
    required String currentPassword,
    required String newPassword,
  })
  onChangePassword;
  final Future<void> Function({
    required String newEmail,
    required String currentPassword,
  })?
  onStartEmailChange;
  final Future<void> Function({required String newEmail, required String code})?
  onVerifyEmailChange;
  final Future<void> Function({required String currentPassword})?
  onRemoveAccount;

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
                if (onStartEmailChange != null &&
                    onVerifyEmailChange != null) ...[
                  const SizedBox(height: 12),
                  AppListRow(
                    title: 'Change Email',
                    leadingIcon: Icons.alternate_email_rounded,
                    onTap: () => _openChangeEmailDialog(context),
                  ),
                ],
                if (onRemoveAccount != null) ...[
                  const SizedBox(height: 12),
                  AppListRow(
                    title: 'Remove Account',
                    leadingIcon: Icons.person_remove_alt_1_rounded,
                    onTap: () => _openRemoveAccountDialog(context),
                  ),
                ],
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
            AccountChangePasswordDialog(onChangePassword: onChangePassword),
      ),
    );
  }

  void _openChangeEmailDialog(BuildContext context) {
    final startHandler = onStartEmailChange;
    final verifyHandler = onVerifyEmailChange;
    if (startHandler == null || verifyHandler == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => AccountChangeEmailDialog(
          onStartEmailChange: startHandler,
          onVerifyEmailChange: verifyHandler,
        ),
      ),
    );
  }

  void _openRemoveAccountDialog(BuildContext context) {
    final handler = onRemoveAccount;
    if (handler == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => AccountRemoveDialog(onRemoveAccount: handler),
      ),
    );
  }
}

class AccountChangePasswordDialog extends StatefulWidget {
  const AccountChangePasswordDialog({
    super.key,
    required this.onChangePassword,
  });

  final Future<void> Function({
    required String currentPassword,
    required String newPassword,
  })
  onChangePassword;

  @override
  State<AccountChangePasswordDialog> createState() =>
      _AccountChangePasswordDialogState();
}

class _AccountChangePasswordDialogState
    extends State<AccountChangePasswordDialog> {
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

class AccountChangeEmailDialog extends StatefulWidget {
  const AccountChangeEmailDialog({
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
  State<AccountChangeEmailDialog> createState() =>
      _AccountChangeEmailDialogState();
}

class _AccountChangeEmailDialogState extends State<AccountChangeEmailDialog> {
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

class AccountRemoveDialog extends StatefulWidget {
  const AccountRemoveDialog({super.key, required this.onRemoveAccount});

  final Future<void> Function({required String currentPassword})
  onRemoveAccount;

  @override
  State<AccountRemoveDialog> createState() => _AccountRemoveDialogState();
}

class _AccountRemoveDialogState extends State<AccountRemoveDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  bool _confirmed = false;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(
        title: 'Remove Account',
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
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if ((value ?? '').isEmpty) {
                            return 'Current password is required.';
                          }
                          return null;
                        },
                        onSubmitted: (_) => _removeAccount(),
                      ),
                      const SizedBox(height: 16),
                      CheckboxRow(
                        title: 'I understand this cannot be undone.',
                        value: _confirmed,
                        onChanged: _isSaving
                            ? null
                            : (value) =>
                                  setState(() => _confirmed = value ?? false),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Remove account',
                        icon: Icons.person_remove_alt_1_rounded,
                        isLoading: _isSaving,
                        onPressed: _isSaving || !_confirmed
                            ? null
                            : _removeAccount,
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

  Future<void> _removeAccount() async {
    if (!_confirmed || !_formKey.currentState!.validate()) {
      return;
    }
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.onRemoveAccount(
        currentPassword: _currentPasswordController.text,
      );
      if (!mounted) {
        return;
      }
      navigator.popUntil((route) => route.isFirst);
      messenger.showSnackBar(const SnackBar(content: Text('Account removed.')));
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
