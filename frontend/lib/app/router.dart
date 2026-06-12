import 'package:go_router/go_router.dart';

import 'ui_catalog/ui_component_catalog_screen.dart';
import '../features/auth/presentation/auth_gate.dart';

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
  ],
);
