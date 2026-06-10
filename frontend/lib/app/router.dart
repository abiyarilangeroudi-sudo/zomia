import 'package:go_router/go_router.dart';

import '../features/app_shell/presentation/app_shell_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'app-shell',
      builder: (context, state) => const AppShellScreen(),
    ),
  ],
);
