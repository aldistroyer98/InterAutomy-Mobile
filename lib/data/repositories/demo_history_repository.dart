import '../../domain/entities/history_record.dart';
import '../../domain/repositories/history_repository.dart';

final class DemoHistoryRepository implements HistoryRepository {
  final Map<String, HistoryRecord> _items = {};

  @override
  Future<HistoryRecord?> getByExecutionId(String executionId) async =>
      _items[executionId];

  @override
  Future<void> save(HistoryRecord record) async =>
      _items[record.executionId] = record;

  @override
  Future<void> delete(String executionId) async => _items.remove(executionId);

  @override
  Future<List<HistoryRecord>> search({
    String query = '',
    String? status,
  }) async {
    final needle = query.trim().toLowerCase();
    final values = _items.values.where((record) {
      final matchesQuery =
          needle.isEmpty ||
          record.clientName.toLowerCase().contains(needle) ||
          record.lineNames.any((line) => line.toLowerCase().contains(needle));
      final matchesStatus =
          status == null || status.isEmpty || record.status.name == status;
      return matchesQuery && matchesStatus;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(values);
  }
}
