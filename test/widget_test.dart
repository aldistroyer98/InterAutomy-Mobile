import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interautomy_mobile/app/app.dart';
import 'package:interautomy_mobile/data/demo/demo_automation_gateway.dart';
import 'package:interautomy_mobile/data/demo/demo_seed.dart';
import 'package:interautomy_mobile/domain/entities/app_settings.dart';
import 'package:interautomy_mobile/state/app_controller.dart';
import 'package:interautomy_mobile/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_settings_repository.dart';

Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  FakeSettingsRepository? settingsRepository,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(
        settingsRepository ?? FakeSettingsRepository(),
      ),
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
  return container;
}

void main() {
  testWidgets('teléfono usa NavigationBar y conserva productos al navegar', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    container
        .read(appControllerProvider.notifier)
        .addCatalogProduct(container.read(appControllerProvider).catalog.first);
    await tester.tap(find.text('Productos'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 producto(s)'), findsOneWidget);

    await tester.tap(find.text('Cliente'));
    await tester.pumpAndSettle();
    expect(
      container.read(appControllerProvider).selectedProducts,
      hasLength(1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('pantalla amplia usa NavigationRail sin overflow', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(1100, 800));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selector permite crear un cliente nuevo', (tester) async {
    final container = await pumpApp(tester);
    final originalComment = container
        .read(appControllerProvider)
        .selectedClient!
        .comentarioFinal;
    await tester.tap(find.byKey(const Key('client-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuevo cliente').last);
    await tester.pumpAndSettle();

    final draft = container.read(appControllerProvider).selectedClient!;
    expect(draft.nombre, isEmpty);
    expect(draft.nroOc, isEmpty);
    expect(draft.comentarioFinal, originalComment);
    expect(find.byKey(const Key('client-nombre')), findsOneWidget);
  });

  testWidgets('agrega producto, aumenta cantidad y elimina', (tester) async {
    final container = await pumpApp(tester);
    await tester.tap(find.text('Productos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-product')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-product-line')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(DemoSeed.abbott.nombre).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('product-${DemoSeed.abbott.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('ABT-HGB-001').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-add-product')));
    await tester.pumpAndSettle();

    expect(
      container.read(appControllerProvider).selectedProducts,
      hasLength(1),
    );
    await tester.tap(find.byTooltip('Aumentar cantidad'));
    await tester.pump();
    expect(
      container.read(appControllerProvider).selectedProducts.single.cantidad,
      2,
    );

    await tester.tap(find.byTooltip('Acciones del producto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar').last);
    await tester.pumpAndSettle();
    expect(container.read(appControllerProvider).selectedProducts, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ejecución espera revisión, confirma y crea historial', (
    tester,
  ) async {
    final container = await pumpApp(tester);
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
    expect(find.text('Confirmar cierre del navegador'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('confirm-browser-close')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-browser-close')));
    await tester.pumpAndSettle();
    expect(find.text('Producto enviado.'), findsWidgets);
    expect(container.read(appControllerProvider).history, hasLength(1));

    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(find.text('San Borja'), findsOneWidget);
    expect(find.text('Restaurar envío completo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tema se puede cambiar desde configuración', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = await pumpApp(
      tester,
      settingsRepository: FakeSettingsRepository(
        settings: const AppSettings(
          demoMode: true,
          portalUrl: '',
          theme: AppThemePreference.system,
        ),
      ),
    );
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Oscuro'),
      300,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey('settings-scroll')),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      ),
    );
    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    expect(
      container.read(appControllerProvider).settings.theme,
      AppThemePreference.dark,
    );

    await tester.tap(find.text('Claro'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
    expect(
      container.read(appControllerProvider).settings.theme,
      AppThemePreference.light,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('modo desarrollador habilita Inspector Web desde configuración', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('developer-mode-switch')),
      500,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey('settings-scroll')),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('developer-mode-switch')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('diagnostic-mode-switch')), findsOneWidget);
    expect(find.byKey(const Key('open-web-inspector')), findsOneWidget);
    await tester.tap(find.byKey(const Key('open-web-inspector')));
    await tester.pumpAndSettle();
    expect(find.text('Inspector Web'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
