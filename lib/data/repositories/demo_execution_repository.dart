import '../../domain/entities/execution.dart';
import '../../domain/repositories/execution_repository.dart';

final class DemoExecutionRepository implements ExecutionRepository {
  final Map<String, Execution> _items = {};

  @override
  Future<List<Execution>> getAll() async {
    final values = _items.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(values);
  }

  @override
  Future<Execution?> getById(String id) async => _items[id];

  @override
  Future<void> save(Execution execution) async =>
      _items[execution.id] = execution;
}
