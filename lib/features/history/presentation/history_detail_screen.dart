import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/execution.dart';
import '../../../state/app_controller.dart';
import '../widgets/history_restore_dialogs.dart';

class HistoryDetailScreen extends ConsumerWidget {
  const HistoryDetailScreen({required this.executionId, super.key});

  final String executionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(appControllerProvider).history;
    final matches = records.where(
      (record) => record.executionId == executionId,
    );
    if (matches.isEmpty) {
      return const Center(child: Text('Registro no encontrado.'));
    }
    final record = matches.first;
    final currency = NumberFormat.currency(locale: 'es_PE', symbol: 'S/');
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.list(
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(record.clientName),
                  subtitle: Text(
                    '${DateFormat('dd/MM/yyyy HH:mm').format(record.createdAt)}\n'
                    '${record.lineNames.join(', ')}',
                  ),
                  trailing: Chip(label: Text(record.status.label)),
                  isThreeLine: true,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => restoreHistoryFlow(
                      context,
                      ref,
                      record,
                      lineOnly: true,
                    ),
                    child: const Text('Restaurar línea'),
                  ),
                  FilledButton(
                    onPressed: () => restoreHistoryFlow(
                      context,
                      ref,
                      record,
                      lineOnly: false,
                    ),
                    child: const Text('Restaurar envío completo'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Productos guardados',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...record.products.map(
                (product) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(product.nombre),
                    subtitle: Text(
                      '${product.codigo} · ${product.linea.nombre}\n'
                      'Cantidad ${product.cantidad} · ${currency.format(product.precio)} · '
                      'Comodato ${product.comodato?.codigo ?? 'Ninguno'}'
                      '${product.expiracion == null ? '' : ' · Expira ${DateFormat('dd/MM/yyyy').format(product.expiracion!)}'}',
                    ),
                    isThreeLine: true,
                    trailing: Text(currency.format(product.subtotal)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
