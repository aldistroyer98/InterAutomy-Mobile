import '../entities/order.dart';

abstract final class OrderValidator {
  static List<String> validate(Order order) {
    final issues = <String>[];
    if (order.client.id.trim().isEmpty || order.client.nombre.trim().isEmpty) {
      issues.add('Selecciona un cliente válido.');
    }
    if (order.products.isEmpty) {
      issues.add('Agrega al menos un producto.');
    }
    for (var index = 0; index < order.products.length; index++) {
      final product = order.products[index];
      final label = 'Producto ${index + 1}';
      if (product.codigo.trim().isEmpty || product.nombre.trim().isEmpty) {
        issues.add('$label: selecciona un producto válido.');
      }
      if (product.linea.id.trim().isEmpty) {
        issues.add('$label: falta la línea.');
      }
      if (product.cantidad <= 0) {
        issues.add('$label: la cantidad debe ser mayor que cero.');
      }
      if (product.precio <= 0) {
        issues.add('$label: el precio debe ser mayor que cero.');
      }
      if (product.requiereComodato && product.comodato == null) {
        issues.add('$label: selecciona un comodato.');
      }
    }
    return List.unmodifiable(issues);
  }
}
