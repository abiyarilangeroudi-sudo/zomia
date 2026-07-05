import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/ui/ui.dart';
import '../../../core/navigation/external_url_launcher.dart';
import '../domain/business_category.dart';
import 'auth_controller.dart';
import 'auth_form_layout.dart';
import 'terms_acceptance_row.dart';

class BusinessRegisterScreen extends ConsumerStatefulWidget {
  const BusinessRegisterScreen({super.key});

  @override
  ConsumerState<BusinessRegisterScreen> createState() =>
      _BusinessRegisterScreenState();
}

class _BusinessRegisterScreenState
    extends ConsumerState<BusinessRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _selectedCategory;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _businessNameController.dispose();
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
          value.user?.isOwner == true) {
        context.go('/');
      }
    });

    return AuthFormLayout(
      title: 'Register Business',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _businessNameController,
                label: 'Business name',
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final name = value?.trim() ?? '';
                  if (name.length < 2) {
                    return 'Business name is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SelectField<String>(
                label: 'Category',
                value: _selectedCategory,
                options: businessCategoryOptions
                    .map(
                      (option) => SelectFieldOption(
                        value: option.value,
                        label: option.label,
                      ),
                    )
                    .toList(),
                onChanged: isLoading
                    ? null
                    : (value) => setState(() => _selectedCategory = value),
                validator: (value) {
                  if (value == null) {
                    return 'Category is required.';
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
                termsLabel: 'Business Terms',
                privacyLabel: 'Privacy',
                value: _acceptedTerms,
                onChanged: isLoading
                    ? null
                    : (value) =>
                          setState(() => _acceptedTerms = value ?? false),
                onTermsTap: () =>
                    openExternalUrl('https://zomia.eu/legal/business-terms'),
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
                label: 'Create business',
                icon: Icons.storefront_rounded,
                onPressed: isLoading ? null : _submit,
                isLoading: isLoading,
              ),
              const SizedBox(height: 12),
              AuthTextLink(
                text: 'Back to Home',
                onPressed: isLoading
                    ? null
                    : () => openExternalUrl('https://zomia.eu/'),
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
        const SnackBar(
          content: Text('Please accept Business Terms & Privacy.'),
        ),
      );
      return;
    }
    final email = _emailController.text.trim();
    await ref
        .read(authControllerProvider.notifier)
        .startOwnerRegistration(
          businessName: _businessNameController.text.trim(),
          businessCategory: _selectedCategory,
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
        queryParameters: {'email': email, 'registration_type': 'owner'},
      ).toString(),
    );
  }
}
