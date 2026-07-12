import '../entities/history_record.dart';

abstract interface class HistoryRepository {
  Future<void> save(HistoryRecord record);
  Future<HistoryRecord?> getByExecutionId(String executionId);
  Future<List<HistoryRecord>> search({String query = '', String? status});
}
