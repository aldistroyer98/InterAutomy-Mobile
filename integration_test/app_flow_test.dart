import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:interautomy_mobile/app/app.dart';
import 'package:interautomy_mobile/data/demo/demo_automation_gateway.dart';
import 'package:interautomy_mobile/state/app_controller.dart';
import 'package:interautomy_mobile/state/providers.dart';

import '../test/helpers/fake_settings_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cliente producto ejecución revisión e historial', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
        automationGatewayProvider.overrideWithValue(
          DemoAutomationGateway(stepDuration: Duration.zero),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(appControllerProvider.notifier).initialize();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const InterAutomyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('San Borja'), findsWidgets);
    final state = container.read(appControllerProvider);
    container
        .read(appControllerProvider.notifier)
        .addCatalogProduct(state.catalog.first);
    await tester.pump();

    await tester.tap(find.text('Ejecución'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('execute-order')));
    await tester.pumpAndSettle();
    expect(find.text('Esperando revisión'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('confirm-browser-close')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-browser-close')));
    await tester.pumpAndSettle();
    expect(find.text('Producto enviado.'), findsWidgets);

    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(find.text('San Borja'), findsOneWidget);
    expect(find.text('Restaurar envío completo'), findsOneWidget);
  });
}
