import '../../domain/entities/commercial_line.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../demo/demo_seed.dart';

final class DemoProductRepository implements ProductRepository {
  @override
  Future<List<CommercialLine>> getLines() async => DemoSeed.lines;

  @override
  Future<List<CatalogProduct>> getProducts({
    String? lineId,
    String query = '',
  }) async {
    final needle = query.trim().toLowerCase();
    return DemoSeed.products
        .where((product) {
          final matchesLine =
              lineId == null || lineId.isEmpty || product.linea.id == lineId;
          final matchesQuery =
              needle.isEmpty ||
              product.codigo.toLowerCase().contains(needle) ||
              product.nombre.toLowerCase().contains(needle) ||
              product.descripcion.toLowerCase().contains(needle);
          return matchesLine && matchesQuery;
        })
        .toList(growable: false);
  }
}
