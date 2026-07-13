import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interautomy_mobile/data/local/local_domain_store.dart';
import 'package:interautomy_mobile/domain/entities/execution.dart';
import 'package:interautomy_mobile/domain/entities/history_record.dart';
import 'package:interautomy_mobile/domain/entities/institution.dart';
import 'package:interautomy_mobile/features/history/application/restore_mode.dart';
import 'package:interautomy_mobile/state/app_controller.dart';
import 'package:interautomy_mobile/state/providers.dart';

import 'helpers/fake_settings_repository.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
        localDomainStoreProvider.overrideWithValue(
          LocalDomainStore(backend: InMemoryLocalDomainStoreBackend()),
        ),
      ],
    );
    await container.read(appControllerProvider.notifier).initialize();
  });

  tearDown(() => container.dispose());

  test('cliente nuevo limpia una vez y conserva condiciones comerciales', () {
    final controller = container.read(appControllerProvider.notifier);
    final original = container.read(appControllerProvider).selectedClient!;
    controller.updateClient(
      original.copyWith(
        nroOc: 'OC-99',
        direccion: 'Dirección temporal',
        comentarioFinal: 'Conservar comentario',
        direccionNueva: true,
        igv: true,
        moneda: 'Dólares',
      ),
    );
    controller.createNewClientDraft();
    final draft = container.read(appControllerProvider).selectedClient!;
    expect(draft.nroOc, isEmpty);
    expect(draft.direccion, isEmpty);
    expect(draft.comentarioFinal, 'Conservar comentario');
    expect(draft.direccionNueva, isTrue);
    expect(draft.igv, isTrue);
    expect(draft.moneda, 'Dólares');

    controller.updateClient(draft.copyWith(nroOc: 'NO BORRAR'));
    expect(
      container.read(appControllerProvider).selectedClient!.nroOc,
      'NO BORRAR',
    );
  });

  test(
    'duplicado por código línea comodato suma cantidad y preserva productos',
    () {
      final controller = container.read(appControllerProvider.notifier);
      final catalog = container.read(appControllerProvider).catalog.first;
      controller.addCatalogProduct(catalog, quantity: 2);
      controller.addCatalogProduct(catalog, quantity: 3);
      final state = container.read(appControllerProvider);
      expect(state.selectedProducts, hasLength(1));
      expect(state.selectedProducts.single.cantidad, 5);

      controller.createNewClientDraft();
      expect(
        container.read(appControllerProvider).selectedProducts,
        hasLength(1),
      );
    },
  );

  test('cantidad puede aumentar, disminuir y eliminar', () {
    final controller = container.read(appControllerProvider.notifier);
    controller.addCatalogProduct(
      container.read(appControllerProvider).catalog.last,
    );
    final id = container.read(appControllerProvider).selectedProducts.single.id;
    controller.changeQuantity(id, 1);
    expect(
      container.read(appControllerProvider).selectedProducts.single.cantidad,
      2,
    );
    controller.changeQuantity(id, -1);
    controller.changeQuantity(id, -1);
    expect(container.read(appControllerProvider).selectedProducts, isEmpty);
  });

  test('restauración agrega duplicados o reemplaza', () {
    final controller = container.read(appControllerProvider.notifier);
    final state = container.read(appControllerProvider);
    controller.addCatalogProduct(state.catalog.first, quantity: 1);
    final snapshot = container
        .read(appControllerProvider)
        .selectedProducts
        .single;
    final record = HistoryRecord(
      id: 'record',
      executionId: 'execution',
      clientId: state.selectedClient!.id,
      clientName: state.selectedClient!.nombre,
      lineNames: [snapshot.linea.nombre],
      createdAt: DateTime(2026),
      status: ExecutionStatus.completed,
      products: [snapshot.copyWith(cantidad: 4)],
    );
    expect(controller.restoreFromHistory(record, mode: RestoreMode.add), 1);
    expect(
      container.read(appControllerProvider).selectedProducts.single.cantidad,
      5,
    );
    expect(controller.restoreFromHistory(record, mode: RestoreMode.replace), 1);
    expect(
      container.read(appControllerProvider).selectedProducts.single.cantidad,
      4,
    );
  });

  test('preferencias se guardan y reflejan en estado', () async {
    final repository =
        container.read(settingsRepositoryProvider) as FakeSettingsRepository;
    final settings = container
        .read(settingsControllerProvider)
        .copyWith(demoMode: false, portalUrl: 'https://automy.example.test');
    await container.read(settingsControllerProvider.notifier).update(settings);
    expect(repository.settings.portalUrl, 'https://automy.example.test');
    expect(container.read(settingsControllerProvider).demoMode, isFalse);
    expect(
      (await container.read(appControllerProvider.notifier).startExecution())
          .valid,
      isFalse,
    );
  });

  test('institución local y perfil restauran el pedido completo', () async {
    final controller = container.read(appControllerProvider.notifier);
    const institution = Institution(
      id: 'institution-local',
      nombre: 'Institución local',
      departamento: 'Lima',
      provincia: 'Lima',
      distrito: 'San Borja',
      direccion: 'Av. Principal 100',
      contacto: 'Responsable local',
      telefono: '999 888 777',
    );
    expect(await controller.saveInstitution(institution), isTrue);
    final selected = container.read(appControllerProvider).selectedClient!;
    expect(selected.institutionId, institution.id);
    expect(selected.institucion, institution.nombre);
    expect(selected.direccion, institution.direccion);

    controller.addCatalogProduct(
      container.read(appControllerProvider).catalog.first,
    );
    expect(await controller.saveProfile('Perfil de prueba'), isTrue);
    final profile = container.read(appControllerProvider).profiles.single;

    controller.createNewClientDraft();
    expect(
      container.read(appControllerProvider).selectedProducts,
      hasLength(1),
    );
    controller.loadProfile(profile);
    final restored = container.read(appControllerProvider);
    expect(restored.selectedClient?.institutionId, institution.id);
    expect(restored.selectedProducts, hasLength(1));
    expect(await controller.deleteProfile(profile.id), isTrue);
    expect(container.read(appControllerProvider).profiles, isEmpty);
  });
}
