import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/responsive_navigation_shell.dart';
import '../features/clients/presentation/clients_screen.dart';
import '../features/execution/presentation/execution_screen.dart';
import '../features/history/presentation/history_detail_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/inspector/presentation/web_inspector_screen.dart';
import '../features/products/presentation/products_screen.dart';
import '../features/portal/presentation/portal_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/clients',
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/clients'),
      GoRoute(
        path: '/portal',
        builder: (context, state) => const PortalScreen(),
      ),
      GoRoute(
        path: '/inspector',
        builder: (context, state) => const WebInspectorScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ResponsiveNavigationShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/clients',
                builder: (context, state) => const ClientsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/products',
                builder: (context, state) => const ProductsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/execution',
                builder: (context, state) => const ExecutionScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
                routes: [
                  GoRoute(
                    path: ':executionId',
                    builder: (context, state) => HistoryDetailScreen(
                      executionId: state.pathParameters['executionId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
