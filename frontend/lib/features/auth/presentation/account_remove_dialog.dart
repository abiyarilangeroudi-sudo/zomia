import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';

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
