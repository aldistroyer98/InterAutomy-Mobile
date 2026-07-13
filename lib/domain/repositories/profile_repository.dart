import '../entities/order_profile.dart';

abstract interface class ProfileRepository {
  Future<List<OrderProfile>> getAll();
  Future<OrderProfile?> getById(String id);
  Future<OrderProfile> save(OrderProfile profile);
  Future<void> delete(String id);
}
