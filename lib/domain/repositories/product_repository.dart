import '../entities/commercial_line.dart';
import '../entities/product.dart';

abstract interface class ProductRepository {
  Future<List<CommercialLine>> getLines();
  Future<List<CatalogProduct>> getProducts({String? lineId, String query = ''});
}
