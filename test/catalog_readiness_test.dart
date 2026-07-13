import 'package:flutter_test/flutter_test.dart';
import 'package:interautomy_mobile/data/demo/demo_seed.dart';
import 'package:interautomy_mobile/domain/entities/catalog_readiness.dart';
import 'package:interautomy_mobile/domain/entities/client.dart';
import 'package:interautomy_mobile/domain/entities/product.dart';

void main() {
  test('cliente completo e incompleto exponen evaluación tipada', () {
    final complete = DemoSeed.clients.first;
    const incomplete = Client(id: 'ia1-client', nombre: 'Cliente IA1');

    expect(complete.readiness, CatalogReadiness.complete);
    expect(complete.missingFields, isEmpty);
    expect(complete.executable, isTrue);
    expect(incomplete.readiness, CatalogReadiness.missingInstitution);
    expect(incomplete.missingFields, contains('institution'));
    expect(incomplete.executable, isFalse);
    expect(incomplete.warnings, isNotEmpty);
  });

  test('producto incompleto conserva todas las causas y bloquea ejecución', () {
    const product = CatalogProduct(
      id: 'ia1-product',
      codigo: '',
      nombre: 'Producto IA1',
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

    expect(product.readiness, CatalogReadiness.missingCommercialCode);
    expect(
      product.missingFields,
      containsAll(<String>[
        'commercialCode',
        'price',
        'presentation',
        'category',
      ]),
    );
    expect(product.executable, isFalse);
    expect(product.warnings, hasLength(4));
  });

  test('comodato se evalúa al seleccionar producto para un cliente', () {
    final catalog = DemoSeed.products.first;
    final unresolved = SelectedProduct.fromCatalog(catalog, id: 'unresolved');
    final resolved = SelectedProduct.fromCatalog(
      catalog,
      id: 'resolved',
      comodato: DemoSeed.comodatoAbbott,
    );

    expect(catalog.readiness, CatalogReadiness.complete);
    expect(unresolved.readiness, CatalogReadiness.missingComodatoMetadata);
    expect(unresolved.executable, isFalse);
    expect(resolved.readiness, CatalogReadiness.complete);
    expect(resolved.executable, isTrue);
  });
}
