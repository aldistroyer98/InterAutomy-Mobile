import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:interautomy_mobile/data/demo/demo_seed.dart';
import 'package:interautomy_mobile/data/local/local_domain_store.dart';
import 'package:interautomy_mobile/domain/entities/client.dart';
import 'package:interautomy_mobile/domain/entities/execution.dart';
import 'package:interautomy_mobile/domain/entities/history_record.dart';
import 'package:interautomy_mobile/domain/entities/institution.dart';
import 'package:interautomy_mobile/domain/entities/order_profile.dart';
import 'package:interautomy_mobile/domain/entities/product.dart';

SelectedProduct _product() => SelectedProduct.fromCatalog(
  DemoSeed.products.first,
  id: 'selected-product',
  comodato: DemoSeed.comodatoAbbott,
);

void main() {
  test(
    'almacenamiento local versionado conserva snapshots completos',
    () async {
      final backend = InMemoryLocalDomainStoreBackend();
      final store = LocalDomainStore(backend: backend);
      final client = DemoSeed.clients.first.copyWith(
        institutionId: 'institution-1',
        archivoOc: 'content://provider/oc-1',
        archivoOcNombre: 'oc.pdf',
        archivoOcMimeType: 'application/pdf',
      );
      const institution = Institution(
        id: 'institution-1',
        nombre: 'Hospital San Borja',
        departamento: 'Lima',
      );
      final product = _product();
      final history = HistoryRecord(
        id: 'history-1',
        executionId: 'execution-1',
        clientId: client.id,
        clientName: client.nombre,
        lineNames: [product.linea.nombre],
        createdAt: DateTime.utc(2026, 7, 12, 10),
        status: ExecutionStatus.completed,
        products: [product],
        clientSnapshot: client,
        executionMode: 'Demo',
        result: 'Completado',
        totalSnapshot: product.subtotal,
      );
      final profile = OrderProfile(
        id: 'profile-1',
        name: 'Hospital recurrente',
        client: client,
        products: [product],
        createdAt: DateTime.utc(2026, 7, 12, 10),
        updatedAt: DateTime.utc(2026, 7, 12, 11),
      );

      await store.saveClient(client);
      await store.saveInstitution(institution);
      await store.saveHistory(history);
      await store.saveProfile(profile);

      final restored = LocalDomainStore(backend: backend);
      expect((await restored.getClients()).single.archivoOcNombre, 'oc.pdf');
      expect(
        (await restored.getClients()).single.institutionId,
        'institution-1',
      );
      expect(
        (await restored.getInstitutions()).single.nombre,
        'Hospital San Borja',
      );
      final restoredHistory = (await restored.getHistory()).single;
      expect(
        restoredHistory.clientSnapshot?.archivoOc,
        'content://provider/oc-1',
      );
      expect(restoredHistory.executionMode, 'Demo');
      expect(restoredHistory.total, product.subtotal);
      expect(
        (await restored.getProfiles()).single.products.single.codigo,
        product.codigo,
      );
      final serialized =
          jsonDecode(backend.primaryContents!) as Map<String, dynamic>;
      expect(serialized['schemaVersion'], LocalDomainStore.schemaVersion);
      expect(
        serialized['checksum'],
        isA<String>().having((it) => it.length, 'length', 64),
      );

      await restored.deleteHistory('execution-1');
      await restored.deleteProfile('profile-1');
      expect(await restored.getHistory(), isEmpty);
      expect(await restored.getProfiles(), isEmpty);
    },
  );

  test('migra el documento v0 sin versión a esquema actual', () async {
    final backend = InMemoryLocalDomainStoreBackend();
    await backend.write(
      jsonEncode({
        'clients': [
          {'id': 'legacy-client', 'name': 'Cliente legado'},
        ],
      }),
    );

    final store = LocalDomainStore(backend: backend);
    final clients = await store.getClients();
    expect(clients.single.nombre, 'Cliente legado');
    await store.saveClient(
      const Client(id: 'new-client', nombre: 'Cliente nuevo'),
    );
    final serialized =
        jsonDecode((await backend.read())!) as Map<String, dynamic>;
    expect(serialized['schemaVersion'], LocalDomainStore.schemaVersion);
    expect((serialized['clients'] as List), hasLength(2));
    expect(serialized['checksum'], isNotEmpty);
  });

  test('migra el documento v1 y lo reescribe con checksum', () async {
    final backend = InMemoryLocalDomainStoreBackend(
      primaryContents: jsonEncode({
        'schemaVersion': 1,
        'clients': [
          {'id': 'v1-client', 'name': 'Cliente v1'},
        ],
        'institutions': const [],
        'history': const [],
        'profiles': const [],
      }),
    );
    final store = LocalDomainStore(backend: backend);

    expect((await store.getClients()).single.id, 'v1-client');
    await store.saveClient(const Client(id: 'v2-client', nombre: 'Cliente v2'));

    final serialized =
        jsonDecode(backend.primaryContents!) as Map<String, dynamic>;
    expect(serialized['schemaVersion'], 2);
    expect(serialized['checksum'], hasLength(64));
  });

  test(
    'recupera JSON truncado desde el backup y repara el principal',
    () async {
      final backend = InMemoryLocalDomainStoreBackend();
      final store = LocalDomainStore(backend: backend);
      await store.saveClient(
        const Client(id: 'safe', nombre: 'Cliente seguro'),
      );
      await store.saveClient(
        const Client(id: 'latest', nombre: 'Cliente reciente'),
      );
      final validBackup = backend.backupContents;
      backend.primaryContents = '{"schemaVersion":2,"clients":[';

      final recovered = LocalDomainStore(backend: backend);
      expect((await recovered.getClients()).map((client) => client.id), [
        'safe',
      ]);
      expect(backend.primaryContents, validBackup);
    },
  );

  test('reporta error tipado si principal y backup están corruptos', () async {
    final store = LocalDomainStore(
      backend: InMemoryLocalDomainStoreBackend(
        primaryContents: '{',
        backupContents: '[',
      ),
    );

    await expectLater(
      store.getClients(),
      throwsA(
        isA<LocalDomainStoreException>().having(
          (error) => error.code,
          'code',
          'LOCAL_STORE_RECOVERY_FAILED',
        ),
      ),
    );
  });

  test(
    'detecta manipulación por checksum sin ocultarla como datos vacíos',
    () async {
      final backend = InMemoryLocalDomainStoreBackend();
      await LocalDomainStore(
        backend: backend,
      ).saveClient(const Client(id: 'client', nombre: 'Original'));
      final document =
          jsonDecode(backend.primaryContents!) as Map<String, dynamic>;
      (document['clients'] as List).first['name'] = 'Alterado';
      backend.primaryContents = jsonEncode(document);
      backend.backupContents = null;

      await expectLater(
        LocalDomainStore(backend: backend).getClients(),
        throwsA(
          isA<LocalDomainStoreException>().having(
            (error) => error.code,
            'code',
            'LOCAL_STORE_CHECKSUM_INVALID',
          ),
        ),
      );
    },
  );

  test('serializa escrituras concurrentes sin perder entidades', () async {
    final backend = InMemoryLocalDomainStoreBackend();
    final store = LocalDomainStore(backend: backend);

    await Future.wait([
      for (var index = 0; index < 25; index++)
        store.saveClient(Client(id: 'client-$index', nombre: 'Cliente $index')),
    ]);

    final reopened = LocalDomainStore(backend: backend);
    expect(await reopened.getClients(), hasLength(25));
  });

  test('escritura física conserva backup y elimina temporales', () async {
    final directory = await Directory.systemTemp.createTemp(
      'interautomy-store-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final backend = ApplicationDocumentsLocalDomainStoreBackend(
      directoryResolver: () async => directory,
    );

    await backend.write('primero');
    await backend.write('segundo');

    expect(await backend.read(), 'segundo');
    expect(await backend.readBackup(), 'primero');
    expect(
      File(
        '${directory.path}${Platform.pathSeparator}interautomy_data.json.tmp',
      ).existsSync(),
      isFalse,
    );
  });

  test('un cierre durante escritura conserva disco y caché previos', () async {
    final seed = InMemoryLocalDomainStoreBackend();
    await LocalDomainStore(
      backend: seed,
    ).saveClient(const Client(id: 'persisted', nombre: 'Persistido'));
    final backend = _InterruptedWriteBackend(seed.primaryContents!);
    final store = LocalDomainStore(backend: backend);
    expect((await store.getClients()).single.id, 'persisted');

    await expectLater(
      store.saveClient(const Client(id: 'lost', nombre: 'No persistido')),
      throwsStateError,
    );
    expect((await store.getClients()).map((client) => client.id), [
      'persisted',
    ]);
    expect(
      (await LocalDomainStore(
        backend: backend,
      ).getClients()).map((client) => client.id),
      ['persisted'],
    );
  });
}

final class _InterruptedWriteBackend implements LocalDomainStoreBackend {
  _InterruptedWriteBackend(this.primary);

  String primary;

  @override
  Future<String?> read() async => primary;

  @override
  Future<String?> readBackup() async => null;

  @override
  Future<void> restore(String contents) async {
    primary = contents;
  }

  @override
  Future<void> write(String contents) async {
    throw StateError('Interrupción simulada antes del reemplazo atómico.');
  }
}
