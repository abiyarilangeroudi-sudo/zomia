import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/ui/ui.dart';
import 'auth_controller.dart';
import 'auth_form_layout.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.registrationType,
  });

  final String email;
  final String registrationType;

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final error = authState.error?.toString();

    ref.listen(authControllerProvider, (_, next) {
      final value = next.asData?.value;
      if (value != null && value.isAuthenticated) {
        context.go('/');
      }
    });

    return AuthFormLayout(
      title: 'Verify Email',
      children: [
        Text(
          'Enter the 6-digit code sent to ${widget.email}.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                onSubmitted: (_) => _submit(),
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                InlineBanner(
                  message: error,
                  tone: BannerTone.error,
                  onClose: ref.read(authControllerProvider.notifier).clearError,
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Verify email',
                icon: Icons.mark_email_read_rounded,
                onPressed: isLoading ? null : _submit,
                isLoading: isLoading,
              ),
              const SizedBox(height: 12),
              AuthTextLink(
                text: 'Back to registration',
                onPressed: isLoading ? null : _goBackToRegistration,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final notifier = ref.read(authControllerProvider.notifier);
    final code = _codeController.text.trim();
    if (widget.registrationType == 'owner') {
      notifier.verifyOwnerRegistration(email: widget.email, code: code);
      return;
    }
    notifier.verifyCustomerRegistration(email: widget.email, code: code);
  }

  void _goBackToRegistration() {
    if (widget.registrationType == 'owner') {
      context.go('/register/business');
      return;
    }
    context.go('/register');
  }
}
