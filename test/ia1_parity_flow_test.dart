import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interautomy_mobile/data/demo/demo_automation_gateway.dart';
import 'package:interautomy_mobile/data/demo/demo_seed.dart';
import 'package:interautomy_mobile/data/local/local_domain_store.dart';
import 'package:interautomy_mobile/domain/entities/app_settings.dart';
import 'package:interautomy_mobile/domain/entities/catalog_source.dart';
import 'package:interautomy_mobile/domain/entities/client.dart';
import 'package:interautomy_mobile/domain/entities/commercial_line.dart';
import 'package:interautomy_mobile/domain/entities/product.dart';
import 'package:interautomy_mobile/domain/repositories/client_repository.dart';
import 'package:interautomy_mobile/domain/repositories/product_repository.dart';
import 'package:interautomy_mobile/state/app_controller.dart';
import 'package:interautomy_mobile/state/providers.dart';

import 'helpers/fake_settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'flujo Demo con fixture IA1 válido persiste perfil e historial',
    () async {
      final backend = InMemoryLocalDomainStoreBackend();
      final settings = FakeSettingsRepository(
        settings: const AppSettings(
          demoMode: true,
          portalUrl: '',
          developerMode: true,
          catalogSource: CatalogSource.ia1,
          theme: AppThemePreference.system,
        ),
      );
      var container = _container(backend, settings, DemoSeed.products.last);
      await container.read(appControllerProvider.notifier).initialize();
      final controller = container.read(appControllerProvider.notifier);
      final initial = container.read(appControllerProvider);

      expect(initial.errorCode, isNull, reason: initial.developerErrorDetails);
      expect(initial.selectedClient?.executable, isTrue);
      expect(initial.catalog.single.executable, isTrue);
      controller.addCatalogProduct(initial.catalog.single);
      expect((await controller.startExecution()).valid, isTrue);
      expect(
        container.read(appControllerProvider).execution?.estado.name,
        'waitingForReview',
      );
      expect(await controller.confirmBrowserClosed(), isTrue);
      expect(await controller.saveProfile('Perfil IA1'), isTrue);
      container.dispose();

      container = _container(backend, settings, DemoSeed.products.last);
      addTearDown(container.dispose);
      await container.read(appControllerProvider.notifier).initialize();
      expect(container.read(appControllerProvider).history, hasLength(1));
      expect(
        container.read(appControllerProvider).profiles.single.name,
        'Perfil IA1',
      );
    },
  );

  test(
    'fixture IA1 incompleto carga para consulta y bloquea ejecución',
    () async {
      const product = CatalogProduct(
        id: 'incomplete',
        codigo: '',
        nombre: 'Producto consultable',
        descripcion: '',
        linea: DemoSeed.abbott,
        presentacion: '',
        precio: 0,
        categoria: '',
        hasVerifiedCode: false,
        hasVerifiedPrice: false,
        hasVerifiedPresentation: false,
        hasVerifiedCategory: false,
      );
      final container = _container(
        InMemoryLocalDomainStoreBackend(),
        FakeSettingsRepository(
          settings: const AppSettings(
            demoMode: true,
            portalUrl: '',
            developerMode: true,
            catalogSource: CatalogSource.ia1,
            theme: AppThemePreference.system,
          ),
        ),
        product,
      );
      addTearDown(container.dispose);
      final controller = container.read(appControllerProvider.notifier);
      await controller.initialize();

      expect(
        container.read(appControllerProvider).errorCode,
        isNull,
        reason: container.read(appControllerProvider).developerErrorDetails,
      );
      expect(
        container.read(appControllerProvider).catalog.single.nombre,
        isNotEmpty,
      );
      controller.addCatalogProduct(product);
      final validation = await controller.startExecution();
      expect(validation.valid, isFalse);
      expect(
        validation.errors.map((issue) => issue.code),
        containsAll(<String>[
          'PRICE_REQUIRED',
          'COMMERCIAL_CODE_REQUIRED',
          'PRESENTATION_REQUIRED',
          'CATEGORY_REQUIRED',
        ]),
      );
      expect(container.read(appControllerProvider).history, isEmpty);
    },
  );
}

ProviderContainer _container(
  InMemoryLocalDomainStoreBackend backend,
  FakeSettingsRepository settings,
  CatalogProduct product,
) => ProviderContainer(
  overrides: [
    settingsRepositoryProvider.overrideWithValue(settings),
    localDomainStoreProvider.overrideWithValue(
      LocalDomainStore(backend: backend),
    ),
    ia1ClientRepositoryProvider.overrideWithValue(
      _ClientFixtureRepository(DemoSeed.clients.first),
    ),
    ia1ProductRepositoryProvider.overrideWithValue(
      _ProductFixtureRepository(product),
    ),
    demoAutomationGatewayProvider.overrideWithValue(
      DemoAutomationGateway(stepDuration: Duration.zero),
    ),
  ],
);

final class _ClientFixtureRepository implements ClientRepository {
  _ClientFixtureRepository(this.client);

  Client client;

  @override
  Future<List<Client>> getAll() async => [client];

  @override
  Future<Client?> getById(String id) async => id == client.id ? client : null;

  @override
  Future<Client> save(Client client) async => this.client = client;

  @override
  Future<List<Client>> search(String query) async => [
    if (query.isEmpty ||
        client.nombre.toLowerCase().contains(query.toLowerCase()))
      client,
  ];
}

final class _ProductFixtureRepository implements ProductRepository {
  const _ProductFixtureRepository(this.product);

  final CatalogProduct product;

  @override
  Future<List<CommercialLine>> getLines() async => [product.linea];

  @override
  Future<List<CatalogProduct>> getProducts({
    String? lineId,
    String query = '',
  }) async => [
    if ((lineId == null || lineId == product.linea.id) &&
        (query.isEmpty ||
            product.nombre.toLowerCase().contains(query.toLowerCase())))
      product,
  ];
}
