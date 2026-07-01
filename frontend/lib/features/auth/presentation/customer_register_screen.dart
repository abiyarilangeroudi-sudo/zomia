import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/ui/ui.dart';
import '../../../core/navigation/external_url_launcher.dart';
import 'auth_form_layout.dart';
import 'auth_controller.dart';
import 'terms_acceptance_row.dart';

class CustomerRegisterScreen extends ConsumerStatefulWidget {
  const CustomerRegisterScreen({super.key});

  @override
  ConsumerState<CustomerRegisterScreen> createState() =>
      _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState
    extends ConsumerState<CustomerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final error = authState.error?.toString();

    ref.listen(authControllerProvider, (_, next) {
      final value = next.asData?.value;
      if (value != null &&
          value.isAuthenticated &&
          value.user?.isCustomer == true) {
        context.go('/');
      }
    });

    return AuthFormLayout(
      title: 'Get Started',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _nameController,
                label: 'Name',
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final name = value?.trim() ?? '';
                  if (name.length < 2) {
                    return 'Name is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 8),
              TermsAcceptanceRow(
                prefix: 'I accept',
                termsLabel: 'Terms',
                privacyLabel: 'Privacy',
                value: _acceptedTerms,
                onChanged: isLoading
                    ? null
                    : (value) =>
                          setState(() => _acceptedTerms = value ?? false),
                onTermsTap: () =>
                    openExternalUrl('https://zomia.eu/legal/terms'),
                onPrivacyTap: () =>
                    openExternalUrl('https://zomia.eu/legal/privacy'),
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
                label: 'Create account',
                icon: Icons.person_add_alt_1_rounded,
                onPressed: isLoading ? null : _submit,
                isLoading: isLoading,
              ),
              const SizedBox(height: 12),
              AuthTextLink(
                text: 'Already have an account? Sign in',
                onPressed: isLoading ? null : () => context.go('/'),
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
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept Terms & Privacy.')),
      );
      return;
    }
    final email = _emailController.text.trim();
    await ref
        .read(authControllerProvider.notifier)
        .startCustomerRegistration(
          fullName: _nameController.text.trim(),
          email: email,
          password: _passwordController.text,
        );
    final hasError = ref.read(authControllerProvider).hasError;
    if (!mounted || hasError) {
      return;
    }
    context.go(
      Uri(
        path: '/verify-email',
        queryParameters: {'email': email, 'registration_type': 'customer'},
      ).toString(),
    );
  }
}
