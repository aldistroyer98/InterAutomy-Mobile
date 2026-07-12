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
  });

  factory SelectedProduct.fromCatalog(
    CatalogProduct product, {
    required String id,
    int cantidad = 1,
    Comodato? comodato,
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

  double get subtotal => precio * cantidad;

  String get duplicateKey => [
    codigo.trim().toLowerCase(),
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
    );
  }
}
