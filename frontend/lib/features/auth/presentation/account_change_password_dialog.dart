import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';

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
                InlineBanner(
                  message: _error!,
                  tone: BannerTone.error,
                  onClose: () => setState(() => _error = null),
                ),
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
