import 'package:flutter_test/flutter_test.dart';
import 'package:interautomy_mobile/data/demo/demo_seed.dart';
import 'package:interautomy_mobile/domain/entities/client.dart';
import 'package:interautomy_mobile/domain/entities/comodato.dart';
import 'package:interautomy_mobile/domain/entities/execution.dart';
import 'package:interautomy_mobile/domain/entities/order.dart';
import 'package:interautomy_mobile/domain/entities/product.dart';
import 'package:interautomy_mobile/domain/services/comodato_resolver.dart';
import 'package:interautomy_mobile/domain/validators/order_validator.dart';

SelectedProduct product({
  int quantity = 2,
  double price = 10,
  bool requiresComodato = false,
  Comodato? comodato,
}) => SelectedProduct.fromCatalog(
  CatalogProduct(
    id: 'catalog',
    codigo: 'P-01',
    nombre: 'Producto',
    descripcion: 'Descripción',
    linea: DemoSeed.abbott,
    presentacion: 'Caja',
    precio: price,
    categoria: 'Reactivo',
    requiereComodato: requiresComodato,
  ),
  id: 'selected',
  cantidad: quantity,
  comodato: comodato,
);

void main() {
  group('cálculos', () {
    test('subtotal multiplica precio por cantidad', () {
      expect(product(quantity: 3, price: 12.5).subtotal, 37.5);
    });

    test('total suma los subtotales', () {
      final order = Order(
        id: 'order',
        client: DemoSeed.clients.first,
        products: [product(), product(quantity: 1, price: 5)],
        createdAt: DateTime(2026),
      );
      expect(order.total, 25);
    });
  });

  group('validación', () {
    test('rechaza cliente vacío', () {
      final order = Order(
        id: 'order',
        client: const Client(id: '', nombre: ''),
        products: [product()],
        createdAt: DateTime(2026),
      );
      expect(
        OrderValidator.validate(order),
        contains('Selecciona un cliente válido.'),
      );
    });

    test('rechaza cantidad, precio y comodato inválidos', () {
      final invalid = product(quantity: 0, price: 0, requiresComodato: true);
      final order = Order(
        id: 'order',
        client: DemoSeed.clients.first,
        products: [invalid],
        createdAt: DateTime(2026),
      );
      final issues = OrderValidator.validate(order);
      expect(issues, hasLength(3));
      expect(issues.join(' '), contains('cantidad'));
      expect(issues.join(' '), contains('precio'));
      expect(issues.join(' '), contains('comodato'));
    });
  });

  group('comodato', () {
    const explicit = Comodato(
      id: 'explicit',
      codigo: 'EXP',
      nombre: 'Explícito',
    );

    test('prioriza explícito, único de línea, general y ninguno', () {
      final sanBorja = DemoSeed.clients.first;
      expect(
        ComodatoResolver.resolve(
          client: sanBorja,
          lineId: DemoSeed.abbott.id,
          explicit: explicit,
        ),
        same(explicit),
      );
      expect(
        ComodatoResolver.resolve(
          client: sanBorja,
          lineId: DemoSeed.abbott.id,
        )?.codigo,
        'CMD240054',
      );
      expect(
        ComodatoResolver.resolve(
          client: DemoSeed.clients[1],
          lineId: DemoSeed.abbott.id,
        )?.codigo,
        'CMD-GENERAL',
      );
      expect(
        ComodatoResolver.resolve(
          client: const Client(id: 'none', nombre: 'Sin comodato'),
          lineId: DemoSeed.abbott.id,
        ),
        isNull,
      );
    });
  });

  test('estados tienen etiquetas en español y terminales correctos', () {
    expect(ExecutionStatus.waitingForReview.label, 'Esperando revisión');
    expect(ExecutionStatus.completed.isTerminal, isTrue);
    expect(ExecutionStatus.cancelled.isTerminal, isTrue);
    expect(ExecutionStatus.fillingInformation.isTerminal, isFalse);
  });
}
