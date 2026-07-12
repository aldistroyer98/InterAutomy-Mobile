import '../../core/errors/app_exception.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/commercial_line.dart';
import '../../domain/entities/execution.dart';
import '../../domain/entities/history_record.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/client_repository.dart';
import '../../domain/repositories/execution_repository.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/repositories/product_repository.dart';

mixin _DisabledRemoteRepository {
  ApiClient get client;

  Never disabled() => throw NetworkException(
    'La integración remota para ${client.baseUrl} está desactivada hasta publicar el contrato de API.',
  );
}

final class RemoteClientRepository
    with _DisabledRemoteRepository
    implements ClientRepository {
  RemoteClientRepository(this.client);

  @override
  final ApiClient client;

  @override
  Future<List<Client>> getAll() async => disabled();

  @override
  Future<Client?> getById(String id) async => disabled();

  @override
  Future<Client> save(Client client) async => disabled();
}

final class RemoteProductRepository
    with _DisabledRemoteRepository
    implements ProductRepository {
  RemoteProductRepository(this.client);

  @override
  final ApiClient client;

  @override
  Future<List<CommercialLine>> getLines() async => disabled();

  @override
  Future<List<CatalogProduct>> getProducts({
    String? lineId,
    String query = '',
  }) async => disabled();
}

final class RemoteExecutionRepository
    with _DisabledRemoteRepository
    implements ExecutionRepository {
  RemoteExecutionRepository(this.client);

  @override
  final ApiClient client;

  @override
  Future<List<Execution>> getAll() async => disabled();

  @override
  Future<Execution?> getById(String id) async => disabled();

  @override
  Future<void> save(Execution execution) async => disabled();
}

final class RemoteHistoryRepository
    with _DisabledRemoteRepository
    implements HistoryRepository {
  RemoteHistoryRepository(this.client);

  @override
  final ApiClient client;

  @override
  Future<HistoryRecord?> getByExecutionId(String executionId) async =>
      disabled();

  @override
  Future<void> save(HistoryRecord record) async => disabled();

  @override
  Future<List<HistoryRecord>> search({
    String query = '',
    String? status,
  }) async => disabled();
}
