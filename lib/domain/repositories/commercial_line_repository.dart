import '../entities/commercial_line.dart';

abstract interface class CommercialLineRepository {
  Future<List<CommercialLine>> getAll();
  Future<CommercialLine?> getById(String id);
  Future<List<CommercialLine>> search(String query);
}
