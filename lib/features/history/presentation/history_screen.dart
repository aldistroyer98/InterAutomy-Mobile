import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/execution.dart';
import '../../../domain/entities/history_record.dart';
import '../../../state/app_controller.dart';
import '../widgets/history_restore_dialogs.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _search = TextEditingController();
  ExecutionStatus? _status;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(appControllerProvider).history;
    final needle = _search.text.trim().toLowerCase();
    final records = history
        .where((record) {
          final matchesSearch =
              needle.isEmpty ||
              record.clientName.toLowerCase().contains(needle) ||
              record.lineNames.any(
                (line) => line.toLowerCase().contains(needle),
              );
          return matchesSearch && (_status == null || record.status == _status);
        })
        .toList(growable: false);

    return CustomScrollView(
      key: const PageStorageKey('history-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.list(
            children: [
              TextField(
                key: const Key('history-search'),
                controller: _search,
                decoration: const InputDecoration(
                  labelText: 'Buscar por cliente o línea',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ExecutionStatus?>(
                initialValue: _status,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Filtrar por estado',
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todos los estados'),
                  ),
                  ...ExecutionStatus.values.map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.label),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _status = value),
              ),
              const SizedBox(height: 16),
              Text(
                '${records.length} registro(s)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        if (records.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text('Todavía no hay ejecuciones que coincidan.'),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.separated(
              itemCount: records.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _HistoryCard(record: records[index]),
            ),
          ),
      ],
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  const _HistoryCard({required this.record});

  final HistoryRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = DateFormat('dd/MM/yyyy · HH:mm').format(record.createdAt);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.clientName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(record.status.label)),
              ],
            ),
            Text(record.lineNames.join(', ')),
            const SizedBox(height: 4),
            Text('$date · ${record.products.length} producto(s)'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () =>
                      context.push('/history/${record.executionId}'),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Detalle'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      restoreHistoryFlow(context, ref, record, lineOnly: true),
                  child: const Text('Restaurar línea'),
                ),
                FilledButton(
                  onPressed: () =>
                      restoreHistoryFlow(context, ref, record, lineOnly: false),
                  child: const Text('Restaurar envío completo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
