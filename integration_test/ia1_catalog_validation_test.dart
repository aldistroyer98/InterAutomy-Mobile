import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:interautomy_mobile/data/demo/demo_automation_gateway.dart';
import 'package:interautomy_mobile/data/local/local_domain_store.dart';
import 'package:interautomy_mobile/domain/entities/app_settings.dart';
import 'package:interautomy_mobile/domain/entities/catalog_source.dart';
import 'package:interautomy_mobile/state/app_controller.dart';
import 'package:interautomy_mobile/state/providers.dart';

import '../test/helpers/fake_settings_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('IA1 carga relaciones reales y bloquea precios no verificados', (
    _,
  ) async {
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          FakeSettingsRepository(
            settings: const AppSettings(
              demoMode: true,
              portalUrl: '',
              catalogSource: CatalogSource.ia1,
              theme: AppThemePreference.system,
            ),
          ),
        ),
        localDomainStoreProvider.overrideWithValue(
          LocalDomainStore(backend: InMemoryLocalDomainStoreBackend()),
        ),
        automationGatewayProvider.overrideWithValue(
          DemoAutomationGateway(stepDuration: Duration.zero),
        ),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(appControllerProvider.notifier);
    await controller.initialize();
    final state = container.read(appControllerProvider);
    expect(state.clients, hasLength(3128));
    expect(state.lines, hasLength(62));
    expect(state.catalog, hasLength(8838));

    controller.addCatalogProduct(state.catalog.first);
    final validation = controller.validateCurrentOrder();
    expect(
      validation.errors.map((issue) => issue.code),
      contains('PRICE_REQUIRED'),
    );
  });
}
