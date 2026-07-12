import '../entities/client.dart';

abstract interface class ClientRepository {
  Future<List<Client>> getAll();
  Future<Client?> getById(String id);
  Future<Client> save(Client client);
}
