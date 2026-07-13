import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interautomy_mobile/automation/webview_automation_gateway.dart';
import 'package:interautomy_mobile/data/demo/demo_automation_gateway.dart';
import 'package:interautomy_mobile/data/local/local_domain_store.dart';
import 'package:interautomy_mobile/domain/entities/app_settings.dart';
import 'package:interautomy_mobile/features/execution/presentation/execution_screen.dart';
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
  testWidgets(
    'el grafo real de providers no tiene ciclo y reconstruye el motor',
    (tester) async {
      const demoSettings = AppSettings(
        demoMode: true,
        portalUrl: '',
        theme: AppThemePreference.system,
      );
      var container = _container(demoSettings);
      addTearDown(() => container.dispose());

      expect(container.read(settingsRepositoryProvider), isNotNull);
      expect(container.read(settingsControllerProvider), demoSettings);
      expect(
        container.read(demoAutomationGatewayProvider),
        isA<DemoAutomationGateway>(),
      );
      expect(
        container.read(webViewAutomationGatewayProvider),
        isA<WebViewAutomationGateway>(),
      );
      expect(
        container.read(automationGatewayProvider),
        isA<DemoAutomationGateway>(),
      );

      final controller = container.read(appControllerProvider.notifier);
      await controller.initialize();
      final initial = container.read(appControllerProvider);
      expect(initial.initialized, isTrue);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: ExecutionScreen())),
        ),
      );
      await tester.pump();
      expect(find.byType(ExecutionScreen), findsOneWidget);
      expect(find.byKey(const Key('execute-order')), findsOneWidget);
      controller.addCatalogProduct(initial.catalog.first);

      final demoExecution = controller.startExecution();
      await tester.pump(const Duration(seconds: 4));
      expect((await demoExecution).valid, isTrue);
      expect(
        container.read(appControllerProvider).execution?.estado.name,
        'waitingForReview',
      );
      final confirmation = controller.confirmBrowserClosed();
      await tester.pump(const Duration(milliseconds: 400));
      expect(await confirmation, isTrue);
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

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      container.dispose();
      container = _container(demoSettings);
      expect(container.read(settingsRepositoryProvider), isNotNull);
      expect(container.read(settingsControllerProvider), demoSettings);
      expect(
        container.read(demoAutomationGatewayProvider),
        isA<DemoAutomationGateway>(),
      );
      expect(
        container.read(webViewAutomationGatewayProvider),
        isA<WebViewAutomationGateway>(),
      );
      expect(
        container.read(automationGatewayProvider),
        isA<DemoAutomationGateway>(),
      );
      await container.read(appControllerProvider.notifier).initialize();
      expect(container.read(appControllerProvider).initialized, isTrue);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: ExecutionScreen())),
        ),
      );
      await tester.pump();
      expect(find.byType(ExecutionScreen), findsOneWidget);
    },
  );
}
