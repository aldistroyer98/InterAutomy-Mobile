import 'client.dart';
import 'commercial_line.dart';
import 'product.dart';

final class Order {
  const Order({
    required this.id,
    required this.client,
    required this.products,
    required this.createdAt,
  });

  final String id;
  final Client client;
  final List<SelectedProduct> products;
  final DateTime createdAt;

  double get total =>
      products.fold(0, (sum, product) => sum + product.subtotal);

  List<CommercialLine> get lines {
    final unique = <String, CommercialLine>{};
    for (final product in products) {
      unique[product.linea.id] = product.linea;
    }
    return List.unmodifiable(unique.values);
  }
}
