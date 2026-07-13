import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/history_record.dart';
import '../../../state/app_controller.dart';
import '../application/restore_mode.dart';

Future<void> restoreHistoryFlow(
  BuildContext context,
  WidgetRef ref,
  HistoryRecord record, {
  required bool lineOnly,
}) async {
  final currentClient = ref.read(appControllerProvider).selectedClient;
  if (currentClient != null && currentClient.id != record.clientId) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('El cliente no coincide'),
        content: Text(
          'El envío pertenece a ${record.clientName}, pero el cliente actual es '
          '${currentClient.nombre}. ¿Deseas continuar y cambiar al cliente del historial?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
  }

  String? lineName;
  if (lineOnly) {
    lineName = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Selecciona la línea',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...record.lineNames.map(
              (line) => ListTile(
                leading: const Icon(Icons.category_outlined),
                title: Text(line),
                onTap: () => Navigator.pop(context, line),
              ),
            ),
          ],
        ),
      ),
    );
    if (lineName == null || !context.mounted) return;
  }

  final mode = await showDialog<RestoreMode>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Restaurar productos'),
      content: const Text(
        'Agregar suma los duplicados al envío actual. Reemplazar elimina los productos actuales.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pop(context, RestoreMode.add),
          child: const Text('Agregar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, RestoreMode.replace),
          child: const Text('Reemplazar'),
        ),
      ],
    ),
  );
  if (mode == null || !context.mounted) return;

  final count = ref
      .read(appControllerProvider.notifier)
      .restoreFromHistory(record, mode: mode, lineName: lineName);
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('Se restauraron $count producto(s).')));
  context.go('/products');
}

Future<void> deleteHistoryFlow(
  BuildContext context,
  WidgetRef ref,
  HistoryRecord record,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Eliminar registro'),
      content: Text(
        '¿Eliminar del historial la ejecución de ${record.clientName}? Esta acción no se puede deshacer.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final deleted = await ref
      .read(appControllerProvider.notifier)
      .deleteHistory(record.executionId);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        deleted ? 'Registro eliminado.' : 'No se pudo eliminar el registro.',
      ),
    ),
  );
}
