import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_version.dart';
import '../../../app/ui/ui.dart';
import 'auth_form_layout.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.initialError, this.initialMessage});

  final String? initialError;
  final String? initialMessage;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isInitialErrorDismissed = false;
  bool _isInitialMessageDismissed = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final initialError = _isInitialErrorDismissed ? null : widget.initialError;
    final authError = authState.error?.toString();
    final error = initialError ?? authError;
    final initialMessage = _isInitialMessageDismissed
        ? null
        : widget.initialMessage;
    final textTheme = Theme.of(context).textTheme;

    return AuthFormLayout(
      title: 'Welcome back',
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => context.push('/ui-catalog'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              AppVersion.label,
              style: textTheme.bodyLarge?.copyWith(
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _emailController,
                label: 'Email',
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
                controller: _passwordController,
                label: 'Password',
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if ((value ?? '').isEmpty) {
                    return 'Password is required.';
                  }
                  return null;
                },
                onSubmitted: (_) => _submit(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: AuthTextLink(
                  text: 'Forgot password?',
                  onPressed: isLoading
                      ? null
                      : () => context.push('/forgot-password'),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                InlineBanner(
                  message: error,
                  tone: BannerTone.error,
                  onClose: _dismissLoginError,
                ),
              ] else if (initialMessage != null) ...[
                const SizedBox(height: 16),
                InlineBanner(
                  message: initialMessage,
                  tone: BannerTone.success,
                  onClose: () =>
                      setState(() => _isInitialMessageDismissed = true),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Sign in',
                icon: Icons.login_rounded,
                onPressed: isLoading ? null : _submit,
                isLoading: isLoading,
              ),
              const SizedBox(height: 12),
              AuthTextLink(
                text: 'Create customer account',
                onPressed: isLoading ? null : () => context.push('/register'),
              ),
              const SizedBox(height: 14),
              AuthTextLink(
                text: 'Register your business',
                onPressed: isLoading
                    ? null
                    : () => context.push('/register/business'),
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
    ref
        .read(authControllerProvider.notifier)
        .signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  void _dismissLoginError() {
    ref.read(authControllerProvider.notifier).clearError();
    setState(() => _isInitialErrorDismissed = true);
  }
}
