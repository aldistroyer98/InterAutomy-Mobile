import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/app_controller.dart';

class HistoryDetailScreen extends ConsumerWidget {
  const HistoryDetailScreen({required this.executionId, super.key});

  final String executionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(appControllerProvider).history;
    final matches = records.where(
      (record) => record.executionId == executionId,
    );
    final record = matches.isEmpty ? null : matches.first;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Detalle del historial',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(record == null ? 'Registro no encontrado.' : record.clientName),
      ],
    );
  }
}
