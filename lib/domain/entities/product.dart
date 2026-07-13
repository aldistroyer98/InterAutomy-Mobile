import 'comodato.dart';
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
