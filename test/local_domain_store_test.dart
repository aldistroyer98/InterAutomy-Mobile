import 'dart:convert';

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
  });
}
