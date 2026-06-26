import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/ui/ui.dart';
import '../data/auth_repository.dart';
import 'auth_form_layout.dart';

class StaffInvitationScreen extends ConsumerStatefulWidget {
  const StaffInvitationScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<StaffInvitationScreen> createState() =>
      _StaffInvitationScreenState();
}

class _StaffInvitationScreenState extends ConsumerState<StaffInvitationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  StaffInvitationPreview? _preview;
  String? _error;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    return AuthFormLayout(
      title: 'Accept Invitation',
      children: [
        if (_isLoading)
          const LoadingState(label: 'Loading invitation')
        else if (preview == null)
          EmptyStateView(
            icon: Icons.mark_email_unread_rounded,
            title: 'Invitation unavailable',
            message: 'Request a new invitation from the business owner.',
            action: SecondaryButton(
              label: 'Back to sign in',
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.go('/'),
            ),
          )
        else
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preview.businessName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        preview.email,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 12),
                AppTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm password',
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
                  label: 'Accept invitation',
                  icon: Icons.mark_email_read_rounded,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _submit,
                ),
                const SizedBox(height: 12),
                AuthTextLink(
                  text: 'Back to sign in',
                  onPressed: _isSaving ? null : () => context.go('/'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _load() async {
    if (widget.token.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'This invitation link is invalid.';
      });
      return;
    }
    try {
      final preview = await ref
          .read(authRepositoryProvider)
          .previewStaffInvitation(token: widget.token);
      if (!mounted) {
        return;
      }
      setState(() {
        _preview = preview;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .acceptStaffInvitation(
            token: widget.token,
            password: _passwordController.text,
          );
      if (!mounted) {
        return;
      }
      context.go('/?message=staff_invitation_accepted');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _isSaving = false;
      });
    }
  }
}
