import 'client.dart';
import 'product.dart';

/// Snapshot local reutilizable de un pedido. No contiene credenciales, cookies
/// ni datos de sesión del portal.
final class OrderProfile {
  const OrderProfile({
    required this.id,
    required this.name,
    required this.client,
    required this.products,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final Client client;
  final List<SelectedProduct> products;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderProfile copyWith({
    String? id,
    String? name,
    Client? client,
    List<SelectedProduct>? products,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => OrderProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    client: client ?? this.client,
    products: products ?? this.products,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
