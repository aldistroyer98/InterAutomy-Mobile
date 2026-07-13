import '../../domain/entities/client.dart';
import '../../domain/repositories/client_repository.dart';
import '../demo/demo_seed.dart';

final class DemoClientRepository implements ClientRepository {
  DemoClientRepository()
    : _clients = {for (final item in DemoSeed.clients) item.id: item};

  final Map<String, Client> _clients;

  @override
  Future<List<Client>> getAll() async => List.unmodifiable(_clients.values);

  @override
  Future<Client?> getById(String id) async => _clients[id];

  @override
  Future<List<Client>> search(String query) async {
    final needle = query.trim().toLowerCase();
    return List.unmodifiable(
      _clients.values
          .where(
            (client) =>
                needle.isEmpty || client.nombre.toLowerCase().contains(needle),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<Client> save(Client client) async {
    _clients[client.id] = client;
    return client;
  }
}
