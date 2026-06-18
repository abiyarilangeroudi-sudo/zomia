import 'package:go_router/go_router.dart';

import 'ui_catalog/ui_component_catalog_screen.dart';
import '../features/auth/presentation/auth_gate.dart';
import '../features/auth/presentation/business_register_screen.dart';
import '../features/auth/presentation/customer_register_screen.dart';
import '../features/auth/presentation/email_verification_screen.dart';
import '../features/auth/presentation/password_recovery_screens.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'auth-gate',
      builder: (context, state) => const AuthGate(),
    ),
    GoRoute(
      path: '/ui-catalog',
      name: 'ui-catalog',
      builder: (context, state) => const UiComponentCatalogScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'customer-register',
      builder: (context, state) => const CustomerRegisterScreen(),
    ),
    GoRoute(
      path: '/register/business',
      name: 'business-register',
      builder: (context, state) => const BusinessRegisterScreen(),
    ),
    GoRoute(
      path: '/verify-email',
      name: 'email-verification',
      builder: (context, state) => EmailVerificationScreen(
        email: state.uri.queryParameters['email'] ?? '',
        registrationType:
            state.uri.queryParameters['registration_type'] ?? 'customer',
      ),
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/password-recovery/verify',
      name: 'password-recovery-verify',
      builder: (context, state) => PasswordRecoveryCodeScreen(
        email: state.uri.queryParameters['email'] ?? '',
      ),
    ),
    GoRoute(
      path: '/password-recovery/reset',
      name: 'password-recovery-reset',
      builder: (context, state) => SetNewPasswordScreen(
        resetToken: state.uri.queryParameters['reset_token'] ?? '',
      ),
    ),
  ],
);
