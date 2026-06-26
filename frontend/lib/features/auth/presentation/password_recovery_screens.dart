import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/ui/ui.dart';
import '../data/auth_repository.dart';
import 'auth_form_layout.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormLayout(
      title: 'Forgot Password',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
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
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                InlineBanner(
                  message: _error!,
                  tone: BannerTone.error,
                  onClose: () => setState(() => _error = null),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Send code',
                icon: Icons.mark_email_unread_rounded,
                onPressed: _isLoading ? null : _submit,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 12),
              AuthTextLink(
                text: 'Back to sign in',
                onPressed: _isLoading ? null : () => context.go('/'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final email = _emailController.text.trim();
    try {
      await ref
          .read(authRepositoryProvider)
          .startPasswordRecovery(email: email);
      if (!mounted) {
        return;
      }
      context.go(
        Uri(
          path: '/password-recovery/verify',
          queryParameters: {'email': email},
        ).toString(),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class PasswordRecoveryCodeScreen extends ConsumerStatefulWidget {
  const PasswordRecoveryCodeScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<PasswordRecoveryCodeScreen> createState() =>
      _PasswordRecoveryCodeScreenState();
}

class _PasswordRecoveryCodeScreenState
    extends ConsumerState<PasswordRecoveryCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormLayout(
      title: 'Verify Reset Code',
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
              if (_error != null) ...[
                const SizedBox(height: 16),
                InlineBanner(
                  message: _error!,
                  tone: BannerTone.error,
                  onClose: () => setState(() => _error = null),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Verify code',
                icon: Icons.verified_rounded,
                onPressed: _isLoading ? null : _submit,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 12),
              AuthTextLink(
                text: 'Back to sign in',
                onPressed: _isLoading ? null : () => context.go('/'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final resetToken = await ref
          .read(authRepositoryProvider)
          .verifyPasswordRecovery(
            email: widget.email,
            code: _codeController.text.trim(),
          );
      if (!mounted) {
        return;
      }
      context.go(
        Uri(
          path: '/password-recovery/reset',
          queryParameters: {'reset_token': resetToken},
        ).toString(),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class SetNewPasswordScreen extends ConsumerStatefulWidget {
  const SetNewPasswordScreen({super.key, required this.resetToken});

  final String resetToken;

  @override
  ConsumerState<SetNewPasswordScreen> createState() =>
      _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends ConsumerState<SetNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormLayout(
      title: 'Set New Password',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _passwordController,
                label: 'Password',
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
                  if (value != _passwordController.text) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                InlineBanner(
                  message: _error!,
                  tone: BannerTone.error,
                  onClose: () => setState(() => _error = null),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Save password',
                icon: Icons.lock_reset_rounded,
                onPressed: _isLoading ? null : _submit,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 12),
              AuthTextLink(
                text: 'Back to sign in',
                onPressed: _isLoading ? null : () => context.go('/'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .completePasswordRecovery(
            resetToken: widget.resetToken,
            newPassword: _passwordController.text,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Please sign in.')),
      );
      context.go('/');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
