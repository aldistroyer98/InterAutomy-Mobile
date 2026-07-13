import 'comodato.dart';
import 'catalog_readiness.dart';
import 'commercial_line.dart';

final class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.linea,
    required this.presentacion,
    required this.precio,
    required this.categoria,
    this.cantidad = 1,
    this.comodato,
    this.expiracion,
    this.requiereComodato = false,
    this.hasVerifiedCode = true,
    this.hasVerifiedPrice = true,
    this.hasVerifiedPresentation = true,
    this.hasVerifiedCategory = true,
    this.comodatoValid = true,
    this.sinComodato = false,
  });

  final String id;
  final String codigo;
  final String nombre;
  final String descripcion;
  final CommercialLine linea;
  final String presentacion;
  final double precio;
  final int cantidad;
  final String categoria;
  final Comodato? comodato;
  final DateTime? expiracion;
  final bool requiereComodato;
  final bool hasVerifiedCode;
  final bool hasVerifiedPrice;
  final bool hasVerifiedPresentation;
  final bool hasVerifiedCategory;
  final bool comodatoValid;
  final bool sinComodato;

  List<String> get missingFields => _missingProductFields(
    id: id,
    code: codigo,
    name: nombre,
    line: linea,
    presentation: presentacion,
    price: precio,
    category: categoria,
    hasVerifiedCode: hasVerifiedCode,
    hasVerifiedPrice: hasVerifiedPrice,
    hasVerifiedPresentation: hasVerifiedPresentation,
    hasVerifiedCategory: hasVerifiedCategory,
    comodatoValid: comodatoValid,
  );

  CatalogReadiness get readiness => _productReadiness(missingFields);

  List<String> get warnings => _productWarnings(missingFields);

  bool get executable => missingFields.isEmpty;
}

final class SelectedProduct {
  const SelectedProduct({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.linea,
    required this.presentacion,
    required this.precio,
    required this.cantidad,
    required this.categoria,
    this.comodato,
    this.expiracion,
    this.requiereComodato = false,
    this.hasVerifiedCode = true,
    this.hasVerifiedPrice = true,
    this.hasVerifiedPresentation = true,
    this.hasVerifiedCategory = true,
    this.comodatoValid = true,
    this.sinComodato = false,
  });

  factory SelectedProduct.fromCatalog(
    CatalogProduct product, {
    required String id,
    int cantidad = 1,
    Comodato? comodato,
    bool comodatoValid = true,
    bool sinComodato = false,
  }) {
    return SelectedProduct(
      id: id,
      codigo: product.codigo,
      nombre: product.nombre,
      descripcion: product.descripcion,
      linea: product.linea,
      presentacion: product.presentacion,
      precio: product.precio,
      cantidad: cantidad,
      categoria: product.categoria,
      comodato: comodato ?? product.comodato,
      expiracion: product.expiracion,
      requiereComodato: product.requiereComodato,
      hasVerifiedCode: product.hasVerifiedCode,
      hasVerifiedPrice: product.hasVerifiedPrice,
      hasVerifiedPresentation: product.hasVerifiedPresentation,
      hasVerifiedCategory: product.hasVerifiedCategory,
      comodatoValid: comodatoValid,
      sinComodato: sinComodato,
    );
  }

  final String id;
  final String codigo;
  final String nombre;
  final String descripcion;
  final CommercialLine linea;
  final String presentacion;
  final double precio;
  final int cantidad;
  final String categoria;
  final Comodato? comodato;
  final DateTime? expiracion;
  final bool requiereComodato;
  final bool hasVerifiedCode;
  final bool hasVerifiedPrice;
  final bool hasVerifiedPresentation;
  final bool hasVerifiedCategory;
  final bool comodatoValid;
  final bool sinComodato;

  List<String> get missingFields => _missingProductFields(
    id: id,
    code: codigo,
    name: nombre,
    line: linea,
    presentation: presentacion,
    price: precio,
    category: categoria,
    hasVerifiedCode: hasVerifiedCode,
    hasVerifiedPrice: hasVerifiedPrice,
    hasVerifiedPresentation: hasVerifiedPresentation,
    hasVerifiedCategory: hasVerifiedCategory,
    comodatoValid: comodatoValid,
    quantity: cantidad,
    comodatoRequired: requiereComodato,
    hasComodato: comodato != null,
  );

  CatalogReadiness get readiness => _productReadiness(missingFields);

  List<String> get warnings => _productWarnings(missingFields);

  bool get executable => missingFields.isEmpty;

  double get subtotal => precio * cantidad;

  String get duplicateKey => [
    (hasVerifiedCode && codigo.trim().isNotEmpty ? codigo : nombre)
        .trim()
        .toLowerCase(),
    linea.id.trim().toLowerCase(),
    comodato?.codigo.trim().toLowerCase() ?? '',
  ].join('|');

  SelectedProduct copyWith({
    String? id,
    double? precio,
    int? cantidad,
    Comodato? comodato,
    bool clearComodato = false,
    DateTime? expiracion,
    bool? comodatoValid,
    bool? sinComodato,
  }) {
    return SelectedProduct(
      id: id ?? this.id,
      codigo: codigo,
      nombre: nombre,
      descripcion: descripcion,
      linea: linea,
      presentacion: presentacion,
      precio: precio ?? this.precio,
      cantidad: cantidad ?? this.cantidad,
      categoria: categoria,
      comodato: clearComodato ? null : comodato ?? this.comodato,
      expiracion: expiracion ?? this.expiracion,
      requiereComodato: requiereComodato,
      hasVerifiedCode: hasVerifiedCode,
      hasVerifiedPrice: hasVerifiedPrice,
      hasVerifiedPresentation: hasVerifiedPresentation,
      hasVerifiedCategory: hasVerifiedCategory,
      comodatoValid: comodatoValid ?? this.comodatoValid,
      sinComodato: sinComodato ?? this.sinComodato,
    );
  }
}

List<String> _missingProductFields({
  required String id,
  required String code,
  required String name,
  required CommercialLine line,
  required String presentation,
  required double price,
  required String category,
  required bool hasVerifiedCode,
  required bool hasVerifiedPrice,
  required bool hasVerifiedPresentation,
  required bool hasVerifiedCategory,
  required bool comodatoValid,
  int? quantity,
  bool comodatoRequired = false,
  bool hasComodato = false,
}) => List.unmodifiable([
  if (id.trim().isEmpty) 'id',
  if (name.trim().isEmpty) 'name',
  if (!hasVerifiedCode || code.trim().isEmpty) 'commercialCode',
  if (line.id.trim().isEmpty || line.nombre.trim().isEmpty) 'line',
  if (!hasVerifiedPrice || price <= 0) 'price',
  if (!hasVerifiedPresentation || presentation.trim().isEmpty) 'presentation',
  if (!hasVerifiedCategory || category.trim().isEmpty) 'category',
  if (quantity != null && quantity <= 0) 'quantity',
  if (comodatoRequired && !hasComodato) 'comodato',
  if (!comodatoValid) 'comodatoMetadata',
]);

CatalogReadiness _productReadiness(List<String> missing) {
  if (missing.contains('id') ||
      missing.contains('name') ||
      missing.contains('quantity')) {
    return CatalogReadiness.notExecutable;
  }
  if (missing.contains('commercialCode')) {
    return CatalogReadiness.missingCommercialCode;
  }
  if (missing.contains('price')) return CatalogReadiness.missingPrice;
  if (missing.contains('line')) return CatalogReadiness.missingLine;
  if (missing.contains('presentation')) {
    return CatalogReadiness.missingPresentation;
  }
  if (missing.contains('category')) return CatalogReadiness.missingCategory;
  if (missing.contains('comodato') || missing.contains('comodatoMetadata')) {
    return CatalogReadiness.missingComodatoMetadata;
  }
  return CatalogReadiness.complete;
}

List<String> _productWarnings(List<String> missing) => List.unmodifiable(
  missing.map((field) => 'Falta completar el campo de producto: $field.'),
);
