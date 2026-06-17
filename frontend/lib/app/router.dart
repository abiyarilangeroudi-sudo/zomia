import 'package:go_router/go_router.dart';

import 'ui_catalog/ui_component_catalog_screen.dart';
import '../features/auth/presentation/auth_gate.dart';
import '../features/auth/presentation/business_register_screen.dart';
import '../features/auth/presentation/customer_register_screen.dart';

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
  ],
);
