import 'package:flutter_test/flutter_test.dart';
import 'package:interautomy_mobile/data/demo/demo_automation_gateway.dart';
import 'package:interautomy_mobile/data/repositories/demo_client_repository.dart';
import 'package:interautomy_mobile/data/repositories/demo_history_repository.dart';
import 'package:interautomy_mobile/data/repositories/demo_product_repository.dart';
import 'package:interautomy_mobile/data/repositories/local_settings_repository.dart';
import 'package:interautomy_mobile/domain/entities/app_settings.dart';
import 'package:interautomy_mobile/domain/entities/execution.dart';
import 'package:interautomy_mobile/domain/entities/history_record.dart';
import 'package:interautomy_mobile/domain/entities/order.dart';
import 'package:interautomy_mobile/domain/entities/product.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'repositorios demo incluyen clientes, líneas y siete productos',
    () async {
      final clients = await DemoClientRepository().getAll();
      final products = DemoProductRepository();
      expect(
        clients.map((item) => item.nombre),
        containsAll(['San Borja', 'Miraflores', 'Surco']),
      );
      expect(await products.getLines(), hasLength(3));
      expect(await products.getProducts(), hasLength(greaterThanOrEqualTo(6)));
    },
  );

  test('gateway emite estados hasta revisión y confirma completado', () async {
    final clients = await DemoClientRepository().getAll();
    final catalog = await DemoProductRepository().getProducts();
    final order = Order(
      id: 'execution-1',
      client: clients.first,
      products: [
        SelectedProduct.fromCatalog(
          catalog.first,
          id: 'selected',
          comodato: clients.first.comodatosPorLinea.values.first.first,
        ),
      ],
      createdAt: DateTime.now(),
    );
    final gateway = DemoAutomationGateway(stepDuration: Duration.zero);
    final states = await gateway
        .execute(order)
        .map((item) => item.estado)
        .toList();
    expect(states.first, ExecutionStatus.pending);
    expect(states.last, ExecutionStatus.waitingForReview);
    final completed = await gateway.confirmBrowserClosed(order.id);
    expect(completed.estado, ExecutionStatus.completed);
    expect(completed.bitacora.last.message, 'Producto enviado.');
  });

  test('historial guarda snapshot y permite buscar', () async {
    final repository = DemoHistoryRepository();
    final record = HistoryRecord(
      id: 'history',
      executionId: 'execution',
      clientId: 'client',
      clientName: 'San Borja',
      lineNames: const ['ABBOTT HEMATOLOGÍA'],
      createdAt: DateTime(2026),
      status: ExecutionStatus.completed,
      products: const <SelectedProduct>[],
    );
    await repository.save(record);
    expect(await repository.getByExecutionId('execution'), same(record));
    expect(await repository.search(query: 'abbott'), [record]);
  });

  test('preferencias locales conservan demo portal y tema', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = LocalSettingsRepository(defaultPortalUrl: '');
    const expected = AppSettings(
      demoMode: false,
      portalUrl: 'https://automy.example.test',
      additionalAllowedHosts: ['login.example.test'],
      theme: AppThemePreference.dark,
    );
    await repository.save(expected);
    final restored = await repository.load();
    expect(restored.demoMode, expected.demoMode);
    expect(restored.portalUrl, expected.portalUrl);
    expect(restored.additionalAllowedHosts, expected.additionalAllowedHosts);
    expect(restored.theme, expected.theme);
  });
}
