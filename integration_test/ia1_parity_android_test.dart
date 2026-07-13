import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
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
import 'package:interautomy_mobile/features/execution/presentation/execution_screen.dart';
import 'package:interautomy_mobile/state/app_controller.dart';
import 'package:interautomy_mobile/state/providers.dart';

import '../test/helpers/fake_settings_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Demo completa IA1 válido y restaura historial/perfil tras reinicio',
    (tester) async {
      final backend = InMemoryLocalDomainStoreBackend();
      final settingsRepository = FakeSettingsRepository(
        settings: const AppSettings(
          demoMode: true,
          portalUrl: '',
          catalogSource: CatalogSource.ia1,
          theme: AppThemePreference.system,
        ),
      );
      var container = _container(
        backend: backend,
        settingsRepository: settingsRepository,
        product: DemoSeed.products.last,
      );

      await container.read(appControllerProvider.notifier).initialize();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: ExecutionScreen())),
        ),
      );
      await tester.pump();
      expect(find.byType(ExecutionScreen), findsOneWidget);

      final controller = container.read(appControllerProvider.notifier);
      final initial = container.read(appControllerProvider);
      expect(initial.selectedClient?.executable, isTrue);
      expect(initial.catalog.single.executable, isTrue);
      controller.addCatalogProduct(initial.catalog.single);
      expect(controller.validateCurrentOrder().valid, isTrue);
      expect((await controller.startExecution()).valid, isTrue);
      expect(
        container.read(appControllerProvider).execution?.estado.name,
        'waitingForReview',
      );
      expect(await controller.confirmBrowserClosed(), isTrue);
      expect(await controller.saveProfile('Perfil Android'), isTrue);
      expect(container.read(appControllerProvider).history, hasLength(1));
      expect(container.read(appControllerProvider).profiles, hasLength(1));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      container.dispose();

      container = _container(
        backend: backend,
        settingsRepository: settingsRepository,
        product: DemoSeed.products.last,
      );
      addTearDown(container.dispose);
      await container.read(appControllerProvider.notifier).initialize();
      final restored = container.read(appControllerProvider);
      expect(restored.history, hasLength(1));
      expect(restored.profiles, hasLength(1));
      expect(restored.profiles.single.name, 'Perfil Android');
      expect(
        container.read(settingsControllerProvider).catalogSource,
        CatalogSource.ia1,
      );
    },
  );

  testWidgets('IA1 incompleto permanece consultable pero no ejecutable', (
    tester,
  ) async {
    const incomplete = CatalogProduct(
      id: 'ia1-incomplete',
      codigo: '',
      nombre: 'Producto IA1 incompleto',
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
      backend: InMemoryLocalDomainStoreBackend(),
      settingsRepository: FakeSettingsRepository(
        settings: const AppSettings(
          demoMode: true,
          portalUrl: '',
          catalogSource: CatalogSource.ia1,
          theme: AppThemePreference.system,
        ),
      ),
      product: incomplete,
    );
    addTearDown(container.dispose);

    final controller = container.read(appControllerProvider.notifier);
    await controller.initialize();
    expect(
      container.read(appControllerProvider).catalog.single.nombre,
      isNotEmpty,
    );
    controller.addCatalogProduct(incomplete);
    final validation = controller.validateCurrentOrder();
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
    expect((await controller.startExecution()).valid, isFalse);
    expect(container.read(appControllerProvider).history, isEmpty);
  });
}

ProviderContainer _container({
  required InMemoryLocalDomainStoreBackend backend,
  required FakeSettingsRepository settingsRepository,
  required CatalogProduct product,
}) => ProviderContainer(
  overrides: [
    settingsRepositoryProvider.overrideWithValue(settingsRepository),
    localDomainStoreProvider.overrideWithValue(
      LocalDomainStore(backend: backend),
    ),
    ia1ClientRepositoryProvider.overrideWithValue(
      _FixtureClientRepository(DemoSeed.clients.first),
    ),
    ia1ProductRepositoryProvider.overrideWithValue(
      _FixtureProductRepository(product),
    ),
    demoAutomationGatewayProvider.overrideWithValue(
      DemoAutomationGateway(stepDuration: Duration.zero),
    ),
  ],
);

final class _FixtureClientRepository implements ClientRepository {
  _FixtureClientRepository(this.client);

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

final class _FixtureProductRepository implements ProductRepository {
  const _FixtureProductRepository(this.product);

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
