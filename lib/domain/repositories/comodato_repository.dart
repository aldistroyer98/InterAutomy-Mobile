import '../entities/comodato.dart';

abstract interface class ComodatoRepository {
  Future<List<Comodato>> getAll();
  Future<Comodato?> getById(String id);
  Future<List<Comodato>> search(String query);
}
