import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/ai/ai_settings_screen.dart';
import '../features/passport/ui/object_detail_screen.dart';
import '../features/passport/ui/objects_screen.dart';
import '../features/passport/ui/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/objects',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _PassportShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/objects',
              builder: (context, state) => const ObjectsScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => ObjectDetailScreen(
                    objectId: state.pathParameters['id']!,
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
              routes: [
                GoRoute(
                  path: 'ai',
                  builder: (context, state) => const AiSettingsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

class _PassportShell extends StatelessWidget {
  const _PassportShell({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.handyman_outlined),
            selectedIcon: Icon(Icons.handyman),
            label: 'Objetos',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

