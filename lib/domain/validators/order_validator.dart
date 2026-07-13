import '../entities/order.dart';
import '../services/order_validation_service.dart';

/// Adaptador temporal para consumidores heredados de la lista de textos.
abstract final class OrderValidator {
  static List<String> validate(Order order) {
    final result = const OrderValidationService().validate(
      client: order.client,
      products: order.products,
    );
    return result.errors.map((issue) => issue.message).toList(growable: false);
  }
}
