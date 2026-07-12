import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/app_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appControllerProvider).settings;
    return ListView(
      key: const PageStorageKey('settings-scroll'),
      padding: const EdgeInsets.all(16),
      children: [
        Text('Configuración', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text(
          settings.demoMode ? 'Modo demostración activo' : 'Modo API activo',
        ),
      ],
    );
  }
}
