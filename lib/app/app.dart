import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/app_settings.dart';
import '../state/app_controller.dart';
import 'app_config.dart';
import 'app_router.dart';
import 'app_theme.dart';

class InterAutomyApp extends ConsumerStatefulWidget {
  const InterAutomyApp({super.key});

  @override
  ConsumerState<InterAutomyApp> createState() => _InterAutomyAppState();
}

class _InterAutomyAppState extends ConsumerState<InterAutomyApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(ref.read(appControllerProvider.notifier).initialize);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final appState = ref.watch(appControllerProvider);
    final themeMode = switch (appState.settings.theme) {
      AppThemePreference.system => ThemeMode.system,
      AppThemePreference.light => ThemeMode.light,
      AppThemePreference.dark => ThemeMode.dark,
    };
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => Stack(
        children: [
          ?child,
          if (appState.loading)
            const ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
