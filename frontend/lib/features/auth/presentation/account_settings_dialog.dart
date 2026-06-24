import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';
import 'account_change_email_dialog.dart';
import 'account_change_password_dialog.dart';
import 'account_remove_dialog.dart';

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
