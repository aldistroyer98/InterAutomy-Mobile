import '../../domain/entities/client.dart';
import '../../domain/entities/history_record.dart';
import '../../domain/entities/institution.dart';
import '../../domain/entities/order_profile.dart';
import '../../domain/repositories/client_repository.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/repositories/institution_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../local/local_domain_store.dart';

final class EmptyInstitutionRepository implements InstitutionRepository {
  const EmptyInstitutionRepository();

  @override
  Future<List<Institution>> getAll() async => const [];

  @override
  Future<Institution?> getById(String id) async => null;

  @override
  Future<List<Institution>> search(String query) async => const [];

  @override
  Future<Institution> save(Institution institution) =>
      Future.value(institution);
}

/// Une el catálogo inmutable elegido por el usuario con los registros locales.
/// Un registro local con el mismo ID reemplaza al catálogo únicamente en el
/// dispositivo; nunca modifica los assets IA1.
final class OverlayClientRepository implements ClientRepository {
  const OverlayClientRepository(this._catalog, this._store);

  final ClientRepository _catalog;
  final LocalDomainStore _store;

  @override
  Future<List<Client>> getAll() async {
    final catalog = await _catalog.getAll();
    final localById = {
      for (final client in await _store.getClients()) client.id: client,
    };
    final result = <Client>[
      for (final client in catalog) localById.remove(client.id) ?? client,
      ...(localById.values.toList()..sort(
        (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
      )),
    ];
    return List.unmodifiable(result);
  }

  @override
  Future<Client?> getById(String id) async {
    final local = (await _store.getClients())
        .where((client) => client.id == id)
        .firstOrNull;
    return local ?? _catalog.getById(id);
  }

  @override
  Future<List<Client>> search(String query) async {
    final needle = query.trim().toLowerCase();
    return List.unmodifiable(
      (await getAll())
          .where(
            (client) =>
                needle.isEmpty || client.nombre.toLowerCase().contains(needle),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<Client> save(Client client) => _store.saveClient(client);
}

final class OverlayInstitutionRepository implements InstitutionRepository {
  const OverlayInstitutionRepository(this._catalog, this._store);

  final InstitutionRepository _catalog;
  final LocalDomainStore _store;

  @override
  Future<List<Institution>> getAll() async {
    final values = <String, Institution>{
      for (final institution in await _catalog.getAll())
        institution.id: institution,
      for (final institution in await _store.getInstitutions())
        institution.id: institution,
    };
    final result = values.values.toList()
      ..sort(
        (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
      );
    return List.unmodifiable(result);
  }

  @override
  Future<Institution?> getById(String id) async {
    final local = (await _store.getInstitutions())
        .where((institution) => institution.id == id)
        .firstOrNull;
    return local ?? _catalog.getById(id);
  }

  @override
  Future<List<Institution>> search(String query) async {
    final needle = query.trim().toLowerCase();
    return List.unmodifiable(
      (await getAll())
          .where(
            (institution) =>
                needle.isEmpty ||
                institution.nombre.toLowerCase().contains(needle),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<Institution> save(Institution institution) async {
    final normalizedName = institution.nombre.trim().toLowerCase();
    final duplicate = (await getAll()).any(
      (current) =>
          current.id != institution.id &&
          current.nombre.trim().toLowerCase() == normalizedName,
    );
    if (duplicate) {
      throw const LocalDomainStoreException(
        'INSTITUTION_DUPLICATE',
        'Ya existe una institución con ese nombre.',
      );
    }
    return _store.saveInstitution(institution);
  }
}

final class PersistentHistoryRepository implements HistoryRepository {
  const PersistentHistoryRepository(this._store);

  final LocalDomainStore _store;

  @override
  Future<HistoryRecord?> getByExecutionId(String executionId) =>
      _store.getHistoryByExecutionId(executionId);

  @override
  Future<void> save(HistoryRecord record) => _store.saveHistory(record);

  @override
  Future<void> delete(String executionId) => _store.deleteHistory(executionId);

  @override
  Future<List<HistoryRecord>> search({
    String query = '',
    String? status,
  }) async {
    final needle = query.trim().toLowerCase();
    return List.unmodifiable(
      (await _store.getHistory())
          .where((record) {
            final matchesQuery =
                needle.isEmpty ||
                record.clientName.toLowerCase().contains(needle) ||
                record.lineNames.any(
                  (line) => line.toLowerCase().contains(needle),
                );
            final matchesStatus =
                status == null ||
                status.isEmpty ||
                record.status.name == status;
            return matchesQuery && matchesStatus;
          })
          .toList(growable: false),
    );
  }
}

final class PersistentProfileRepository implements ProfileRepository {
  const PersistentProfileRepository(this._store);

  final LocalDomainStore _store;

  @override
  Future<void> delete(String id) => _store.deleteProfile(id);

  @override
  Future<List<OrderProfile>> getAll() => _store.getProfiles();

  @override
  Future<OrderProfile?> getById(String id) => _store.getProfileById(id);

  @override
  Future<OrderProfile> save(OrderProfile profile) async {
    final duplicate = (await getAll()).any(
      (current) =>
          current.id != profile.id &&
          current.name.trim().toLowerCase() ==
              profile.name.trim().toLowerCase(),
    );
    if (duplicate) {
      throw const LocalDomainStoreException(
        'PROFILE_DUPLICATE',
        'Ya existe un perfil con ese nombre.',
      );
    }
    return _store.saveProfile(profile);
  }
}
