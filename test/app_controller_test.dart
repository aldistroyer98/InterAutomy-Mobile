import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interautomy_mobile/domain/entities/execution.dart';
import 'package:interautomy_mobile/domain/entities/history_record.dart';
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
        .read(appControllerProvider)
        .settings
        .copyWith(demoMode: false, portalUrl: 'https://automy.example.test');
    await container
        .read(appControllerProvider.notifier)
        .updateSettings(settings);
    expect(repository.settings.portalUrl, 'https://automy.example.test');
    expect(container.read(appControllerProvider).settings.demoMode, isFalse);
    expect(
      await container.read(appControllerProvider.notifier).startExecution(),
      isNotEmpty,
    );
  });
}
