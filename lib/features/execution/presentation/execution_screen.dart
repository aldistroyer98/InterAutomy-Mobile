import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/execution.dart';
import '../../../state/app_controller.dart';

class ExecutionScreen extends ConsumerWidget {
  const ExecutionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    return ListView(
      key: const PageStorageKey('execution-scroll'),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Resumen de ejecución',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          state.execution?.estado.label ??
              'La ejecución todavía no ha comenzado.',
        ),
      ],
    );
  }
}
