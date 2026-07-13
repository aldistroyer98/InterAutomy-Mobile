import 'package:flutter_test/flutter_test.dart';
import 'package:interautomy_mobile/data/catalogs/asset_catalog_loader.dart';
import 'package:interautomy_mobile/data/repositories/asset_catalog_repositories.dart';
import 'package:interautomy_mobile/domain/entities/product.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'catálogos IA1 y manifiesto son válidos y mantienen relaciones',
    () async {
      final loader = AssetCatalogLoader();
      final manifest = await loader.validateManifest();
      expect(
        manifest.sourceDesktopCommit,
        'e238e4788e40d96c7d3f2387dcc60d51123159b0',
      );
      expect(manifest.clients, 3128);
      expect(manifest.lines, 62);
      expect(manifest.products, 8838);
      expect(manifest.institutions, 0);
      expect(manifest.comodatos, 0);

      final clients = await AssetClientRepository(loader).getAll();
      final productRepository = AssetProductRepository(loader);
      final lines = await productRepository.getLines();
      final products = await productRepository.getProducts();
      expect(clients, hasLength(manifest.clients));
      expect(lines, hasLength(manifest.lines));
      expect(products, hasLength(manifest.products));
      expect(
        products.every((product) => lines.contains(product.linea)),
        isTrue,
      );
      expect(products.every((product) => !product.hasVerifiedPrice), isTrue);
      expect(
        products.every(
          (product) => !product.hasVerifiedCode && product.codigo.isEmpty,
        ),
        isTrue,
      );
      final first = products.first;
      expect(
        SelectedProduct.fromCatalog(first, id: 'one').duplicateKey,
        SelectedProduct.fromCatalog(first, id: 'two').duplicateKey,
      );
    },
  );
}
