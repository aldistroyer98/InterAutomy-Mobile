import 'package:flutter_test/flutter_test.dart';
import 'package:interautomy_mobile/data/demo/demo_seed.dart';
import 'package:interautomy_mobile/domain/entities/client.dart';
import 'package:interautomy_mobile/domain/entities/comodato.dart';
import 'package:interautomy_mobile/domain/entities/product.dart';
import 'package:interautomy_mobile/domain/services/comodato_resolution_service.dart';
import 'package:interautomy_mobile/domain/services/order_validation_service.dart';
import 'package:interautomy_mobile/domain/validation/validation_result.dart';

SelectedProduct _product({double price = 12.5, Comodato? comodato}) =>
    SelectedProduct.fromCatalog(
      CatalogProduct(
        id: 'product',
        codigo: 'P-01',
        nombre: 'Producto',
        descripcion: 'Descripción',
        linea: DemoSeed.abbott,
        presentacion: 'Caja',
        precio: price,
        categoria: 'Reactivo',
      ),
      id: 'selected',
      comodato: comodato,
      comodatoValid: true,
    ).copyWith(comodatoValid: true);

void main() {
  const service = OrderValidationService();

  test('la validación tipada acepta el pedido Demo completo', () {
    final result = service.validate(
      client: DemoSeed.clients.first,
      products: [_product(comodato: DemoSeed.comodatoAbbott)],
    );
    expect(result.valid, isTrue);
    expect(result.errors, isEmpty);
  });

  test('la validación tipada identifica campo, código y acción', () {
    final result = service.validate(
      client: const Client(id: 'new', nombre: 'Cliente'),
      products: const [],
    );
    expect(result.valid, isFalse);
    expect(
      result.errors.any(
        (issue) =>
            issue.code == 'INSTITUTION_REQUIRED' &&
            issue.field == 'institution' &&
            issue.correctiveAction.isNotEmpty,
      ),
      isTrue,
    );
    expect(
      result.errors.any((issue) => issue.code == 'PRODUCTS_REQUIRED'),
      isTrue,
    );
  });

  test(
    'un producto IA1 sin precio verificable se bloquea sin inventar total',
    () {
      final unverified = SelectedProduct(
        id: 'ia1',
        codigo: 'ia1-product',
        nombre: 'Producto IA1',
        descripcion: '',
        linea: DemoSeed.abbott,
        presentacion: '',
        precio: 0,
        cantidad: 1,
        categoria: '',
        hasVerifiedCode: false,
        hasVerifiedPrice: false,
        hasVerifiedPresentation: false,
        hasVerifiedCategory: false,
      );
      final result = service.validate(
        client: DemoSeed.clients.first,
        products: [unverified],
      );
      expect(
        result.errors.map((issue) => issue.code),
        contains('PRICE_REQUIRED'),
      );
      expect(
        result.warnings.map((issue) => issue.severity),
        everyElement(ValidationSeverity.warning),
      );
    },
  );

  test('comodato no elige arbitrariamente un general múltiple', () {
    const first = Comodato(id: 'a', codigo: 'A', nombre: 'A', esGeneral: true);
    const second = Comodato(id: 'b', codigo: 'B', nombre: 'B', esGeneral: true);
    const explicit = Comodato(id: 'x', codigo: 'X', nombre: 'X');
    const client = Client(
      id: 'client',
      nombre: 'Cliente',
      comodatosPorLinea: {
        'general': [first, second],
      },
    );
    final automatic = ComodatoResolutionService.resolve(
      client: client,
      lineId: DemoSeed.abbott.id,
    );
    expect(automatic.source, ComodatoResolutionSource.none);
    expect(automatic.comodato, isNull);

    final invalidExplicit = ComodatoResolutionService.resolve(
      client: client,
      lineId: DemoSeed.abbott.id,
      explicit: explicit,
    );
    expect(invalidExplicit.source, ComodatoResolutionSource.invalidExplicit);
    expect(invalidExplicit.valid, isFalse);
  });

  test('comodato respeta explícito, línea, general y sin comodato', () {
    const line = Comodato(id: 'line', codigo: 'LINE', nombre: 'Por línea');
    const general = Comodato(
      id: 'general',
      codigo: 'GENERAL',
      nombre: 'General',
      esGeneral: true,
    );
    const client = Client(
      id: 'client',
      nombre: 'Cliente',
      comodatosPorLinea: {
        'abbott-hematologia': [line],
        'General (heredado)': [general],
      },
    );
    expect(
      ComodatoResolutionService.resolve(
        client: client,
        lineId: DemoSeed.abbott.id,
        explicit: line,
      ).source,
      ComodatoResolutionSource.explicit,
    );
    expect(
      ComodatoResolutionService.resolve(
        client: client,
        lineId: DemoSeed.abbott.id,
      ).source,
      ComodatoResolutionSource.line,
    );
    expect(
      ComodatoResolutionService.resolve(
        client: client,
        lineId: DemoSeed.roche.id,
      ).source,
      ComodatoResolutionSource.general,
    );
    expect(
      ComodatoResolutionService.resolve(
        client: client,
        lineId: DemoSeed.roche.id,
        forceNone: true,
      ).source,
      ComodatoResolutionSource.none,
    );
  });
}
