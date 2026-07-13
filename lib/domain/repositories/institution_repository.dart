import '../entities/institution.dart';

abstract interface class InstitutionRepository {
  Future<List<Institution>> getAll();
  Future<Institution?> getById(String id);
  Future<List<Institution>> search(String query);
  Future<Institution> save(Institution institution);
}
