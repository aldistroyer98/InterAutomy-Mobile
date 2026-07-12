import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../responsive/app_breakpoints.dart';

class ResponsiveNavigationShell extends StatelessWidget {
  const ResponsiveNavigationShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Cliente',
    ),
    NavigationDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2),
      label: 'Productos',
    ),
    NavigationDestination(
      icon: Icon(Icons.play_circle_outline),
      selectedIcon: Icon(Icons.play_circle),
      label: 'Ejecución',
    ),
    NavigationDestination(
      icon: Icon(Icons.history_outlined),
      selectedIcon: Icon(Icons.history),
      label: 'Historial',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Ajustes',
    ),
  ];

  void _select(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sizeClass = AppBreakpoints.of(constraints.maxWidth);
        final compact = sizeClass == WindowSizeClass.compact;
        return Scaffold(
          appBar: AppBar(
            title: Text(_destinations[navigationShell.currentIndex].label),
          ),
          body: SafeArea(
            top: false,
            child: compact
                ? navigationShell
                : Row(
                    children: [
                      NavigationRail(
                        extended: sizeClass == WindowSizeClass.expanded,
                        selectedIndex: navigationShell.currentIndex,
                        onDestinationSelected: _select,
                        labelType: sizeClass == WindowSizeClass.medium
                            ? NavigationRailLabelType.all
                            : NavigationRailLabelType.none,
                        destinations: _destinations
                            .map(
                              (destination) => NavigationRailDestination(
                                icon: destination.icon,
                                selectedIcon: destination.selectedIcon,
                                label: Text(destination.label),
                              ),
                            )
                            .toList(growable: false),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: navigationShell),
                    ],
                  ),
          ),
          bottomNavigationBar: compact
              ? NavigationBar(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _select,
                  destinations: _destinations,
                )
              : null,
        );
      },
    );
  }
}
