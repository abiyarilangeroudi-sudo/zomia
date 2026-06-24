import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/ui/ui.dart';

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
