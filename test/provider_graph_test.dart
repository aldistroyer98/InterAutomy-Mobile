import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interautomy_mobile/automation/webview_automation_gateway.dart';
import 'package:interautomy_mobile/data/demo/demo_automation_gateway.dart';
import 'package:interautomy_mobile/data/local/local_domain_store.dart';
import 'package:interautomy_mobile/domain/entities/app_settings.dart';
import 'package:interautomy_mobile/state/app_controller.dart';
import 'package:interautomy_mobile/state/providers.dart';

import 'helpers/fake_settings_repository.dart';

ProviderContainer _container(AppSettings settings) => ProviderContainer(
  overrides: [
    settingsRepositoryProvider.overrideWithValue(
      FakeSettingsRepository(settings: settings),
    ),
    localDomainStoreProvider.overrideWithValue(
      LocalDomainStore(backend: InMemoryLocalDomainStoreBackend()),
    ),
  ],
);

void main() {
  test(
    'el grafo real de providers no tiene ciclo y reconstruye el motor',
    () async {
      const demoSettings = AppSettings(
        demoMode: true,
        portalUrl: '',
        theme: AppThemePreference.system,
      );
      final container = _container(demoSettings);
      addTearDown(container.dispose);

      expect(container.read(settingsControllerProvider), demoSettings);
      expect(
        container.read(demoAutomationGatewayProvider),
        isA<DemoAutomationGateway>(),
      );
      expect(
        container.read(automationGatewayProvider),
        isA<DemoAutomationGateway>(),
      );

      final controller = container.read(appControllerProvider.notifier);
      await controller.initialize();
      final initial = container.read(appControllerProvider);
      expect(initial.initialized, isTrue);
      controller.addCatalogProduct(initial.catalog.first);

      expect((await controller.startExecution()).valid, isTrue);
      expect(
        container.read(appControllerProvider).execution?.estado.name,
        'waitingForReview',
      );
      expect(await controller.confirmBrowserClosed(), isTrue);
      expect(container.read(appControllerProvider).history, hasLength(1));

      await container
          .read(settingsControllerProvider.notifier)
          .update(demoSettings.copyWith(demoMode: false, portalUrl: ''));
      expect(
        container.read(automationGatewayProvider),
        isA<WebViewAutomationGateway>(),
      );
      final webViewWithoutUrl = await controller.startExecution();
      expect(webViewWithoutUrl.valid, isFalse);
      expect(
        webViewWithoutUrl.errors.map((issue) => issue.code),
        contains('PORTAL_CONFIGURATION_REQUIRED'),
      );

      await container
          .read(settingsControllerProvider.notifier)
          .update(demoSettings);
      expect(
        container.read(automationGatewayProvider),
        isA<DemoAutomationGateway>(),
      );

      container.dispose();
      final rebuilt = _container(demoSettings);
      addTearDown(rebuilt.dispose);
      expect(rebuilt.read(settingsControllerProvider), demoSettings);
      expect(
        rebuilt.read(automationGatewayProvider),
        isA<DemoAutomationGateway>(),
      );
      await rebuilt.read(appControllerProvider.notifier).initialize();
      expect(rebuilt.read(appControllerProvider).initialized, isTrue);
    },
  );
}
