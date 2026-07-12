import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/app_controller.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    return ListView(
      key: const PageStorageKey('history-scroll'),
      padding: const EdgeInsets.all(16),
      children: [
        Text('Historial', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text('${state.history.length} ejecución(es) registrada(s).'),
      ],
    );
  }
}
