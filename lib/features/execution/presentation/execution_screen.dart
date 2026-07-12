import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/execution.dart';
import '../../../state/app_controller.dart';

class ExecutionScreen extends ConsumerWidget {
  const ExecutionScreen({super.key});

  Future<void> _execute(BuildContext context, WidgetRef ref) async {
    final issues = await ref
        .read(appControllerProvider.notifier)
        .startExecution();
    if (!context.mounted || issues.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Validación requerida'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            shrinkWrap: true,
            children: issues
                .map(
                  (issue) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.error_outline),
                    title: Text(issue),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final completed = await ref
        .read(appControllerProvider.notifier)
        .confirmBrowserClosed();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          completed ? 'Producto enviado.' : 'No se pudo completar el envío.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final execution = state.execution;
    final currency = NumberFormat.currency(locale: 'es_PE', symbol: 'S/');
    final running =
        execution != null &&
        !execution.estado.isTerminal &&
        execution.estado != ExecutionStatus.waitingForReview;

    return CustomScrollView(
      key: const PageStorageKey('execution-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.list(
            children: [
              _SummaryCard(
                client: state.selectedClient?.nombre ?? 'Sin cliente',
                lines: state.selectedProducts
                    .map((item) => item.linea.nombre)
                    .toSet()
                    .join(', '),
                products: state.selectedProducts.length,
                total: currency.format(state.total),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              execution?.estado.label ?? 'Lista para ejecutar',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          if (execution != null)
                            Chip(
                              label: Text(
                                '${(execution.progreso * 100).round()} %',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: execution?.progreso ?? 0),
                      if (state.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          state.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            key: const Key('execute-order'),
                            onPressed: running || state.loading
                                ? null
                                : () => _execute(context, ref),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Ejecutar'),
                          ),
                          OutlinedButton.icon(
                            key: const Key('cancel-execution'),
                            onPressed: running
                                ? ref
                                      .read(appControllerProvider.notifier)
                                      .cancelExecution
                                : null,
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Cancelar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (execution?.estado == ExecutionStatus.waitingForReview) ...[
                const SizedBox(height: 12),
                Card(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Revisión manual',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Revise toda la información con paciencia y detalle. '
                          'Cuando haya confirmado el envío, cierre Google Chrome.',
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          key: const Key('confirm-browser-close'),
                          onPressed: state.loading
                              ? null
                              : () => _confirm(context, ref),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Confirmar cierre del navegador'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (execution?.estado == ExecutionStatus.completed) ...[
                const SizedBox(height: 12),
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: const ListTile(
                    leading: Icon(Icons.check_circle),
                    title: Text('Producto enviado.'),
                    subtitle: Text('La ejecución se guardó en el historial.'),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text('Bitácora', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (execution == null || execution.bitacora.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.receipt_long_outlined),
                    title: Text(
                      'La bitácora aparecerá al iniciar una ejecución.',
                    ),
                  ),
                )
              else
                ...execution.bitacora.reversed.map(
                  (entry) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.circle, size: 12),
                      title: Text(entry.message),
                      subtitle: Text(
                        '${DateFormat.Hms('es_PE').format(entry.timestamp)} · ${entry.status.label}',
                      ),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.client,
    required this.lines,
    required this.products,
    required this.total,
  });

  final String client;
  final String lines;
  final int products;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _SummaryItem(label: 'Cliente', value: client),
            _SummaryItem(
              label: 'Líneas',
              value: lines.isEmpty ? 'Sin líneas' : lines,
            ),
            _SummaryItem(label: 'Productos', value: '$products'),
            _SummaryItem(label: 'Total', value: total),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
