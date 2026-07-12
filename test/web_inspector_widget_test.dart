import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interautomy_mobile/automation/detection/page_detector.dart';
import 'package:interautomy_mobile/automation/webview/portal_diagnostics.dart';
import 'package:interautomy_mobile/features/inspector/presentation/web_inspector_screen.dart';
import 'package:interautomy_mobile/state/providers.dart';

Future<ProviderContainer> pumpInspector(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const WebInspectorScreen(),
      ),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  testWidgets('Inspector Web muestra diagnóstico vacío y URL ausente', (
    tester,
  ) async {
    await pumpInspector(tester);
    expect(find.text('Inspector Web'), findsOneWidget);
    expect(find.text('Sin abrir'), findsOneWidget);
    expect(find.text('Sin host'), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('web-inspector-list')),
      const Offset(0, -1600),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('export-web-diagnostic')),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('dominio bloqueado se informa sin ejecutar JavaScript', (
    tester,
  ) async {
    await pumpInspector(tester);
    await tester.drag(
      find.byKey(const Key('web-inspector-list')),
      const Offset(0, -2800),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('detect-nro-oc')));
    await tester.pumpAndSettle();
    expect(find.text('DOMAIN_BLOCKED'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('refleja loading login y clientForm', (tester) async {
    final container = await pumpInspector(tester);
    final gateway = container.read(webViewAutomationGatewayProvider);
    gateway.webController.updateDiagnostics(
      const PortalDiagnostics(loadingProgress: 40, page: PortalPage.login),
    );
    await tester.pump();
    expect(find.text('Cargando 40%'), findsOneWidget);
    expect(find.text('login'), findsOneWidget);

    gateway.webController.updateDiagnostics(
      const PortalDiagnostics(
        loadingProgress: 100,
        page: PortalPage.clientForm,
      ),
    );
    await tester.pump();
    expect(find.text('clientForm'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final configuration in <(String, Size, double)>[
    ('teléfono texto 150%', const Size(390, 844), 1.5),
    ('teléfono texto 200%', const Size(390, 844), 2),
    ('tableta', const Size(900, 1200), 1),
    ('landscape', const Size(844, 390), 1),
  ]) {
    testWidgets('Inspector Web sin overflow en ${configuration.$1}', (
      tester,
    ) async {
      await pumpInspector(
        tester,
        size: configuration.$2,
        textScale: configuration.$3,
      );
      expect(find.byKey(const Key('web-inspector-list')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
