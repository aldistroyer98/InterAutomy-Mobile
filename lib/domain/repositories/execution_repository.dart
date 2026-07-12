import '../entities/execution.dart';

abstract interface class ExecutionRepository {
  Future<void> save(Execution execution);
  Future<Execution?> getById(String id);
  Future<List<Execution>> getAll();
}
