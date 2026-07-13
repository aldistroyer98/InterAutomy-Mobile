import '../../domain/entities/client.dart';
import '../../domain/entities/commercial_line.dart';
import '../../domain/entities/comodato.dart';
import '../../domain/entities/institution.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/client_repository.dart';
import '../../domain/repositories/commercial_line_repository.dart';
import '../../domain/repositories/comodato_repository.dart';
import '../../domain/repositories/institution_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../catalogs/asset_catalog_loader.dart';

final class AssetClientRepository implements ClientRepository {
  AssetClientRepository(this._loader);

  final AssetCatalogLoader _loader;
  Future<List<Client>>? _cache;

  Future<List<Client>> _all() => _cache ??= _loader
      .validateManifest()
      .then((_) => _loader.items(AssetCatalogLoader.clientsPath))
      .then(
        (items) => List.unmodifiable(
          items.map(
            (item) =>
                Client(id: _text(item, 'id'), nombre: _text(item, 'name')),
          ),
        ),
      );

  @override
  Future<List<Client>> getAll() => _all();

  @override
  Future<Client?> getById(String id) async {
    for (final client in await _all()) {
      if (client.id == id) return client;
    }
    return null;
  }

  @override
  Future<List<Client>> search(String query) async {
    final needle = query.trim().toLowerCase();
    return List.unmodifiable(
      (await _all())
          .where(
            (client) =>
                needle.isEmpty || client.nombre.toLowerCase().contains(needle),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<Client> save(Client client) => Future.error(
    const CatalogLoadException(
      'El catálogo IA1 es de solo lectura; guarda el cliente personalizado localmente.',
    ),
  );
}

final class AssetInstitutionRepository implements InstitutionRepository {
  AssetInstitutionRepository(this._loader);

  final AssetCatalogLoader _loader;
  Future<List<Institution>>? _cache;

  Future<List<Institution>> _all() => _cache ??= _loader
      .validateManifest()
      .then((_) => _loader.items(AssetCatalogLoader.institutionsPath))
      .then(
        (items) => List.unmodifiable(
          items.map(
            (item) =>
                Institution(id: _text(item, 'id'), nombre: _text(item, 'name')),
          ),
        ),
      );

  @override
  Future<List<Institution>> getAll() => _all();

  @override
  Future<Institution?> getById(String id) async {
    for (final institution in await _all()) {
      if (institution.id == id) return institution;
    }
    return null;
  }

  @override
  Future<List<Institution>> search(String query) async {
    final needle = query.trim().toLowerCase();
    return List.unmodifiable(
      (await _all())
          .where(
            (institution) =>
                needle.isEmpty ||
                institution.nombre.toLowerCase().contains(needle),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<Institution> save(Institution institution) => Future.error(
    const CatalogLoadException(
      'El catálogo IA1 es de solo lectura; guarda la institución personalizada localmente.',
    ),
  );
}

final class AssetCommercialLineRepository implements CommercialLineRepository {
  AssetCommercialLineRepository(this._loader);

  final AssetCatalogLoader _loader;
  Future<List<CommercialLine>>? _cache;

  Future<List<CommercialLine>> _all() => _cache ??= _loader
      .validateManifest()
      .then((_) => _loader.items(AssetCatalogLoader.linesPath))
      .then(
        (items) => List.unmodifiable(
          items.map(
            (item) => CommercialLine(
              id: _text(item, 'id'),
              nombre: _text(item, 'name'),
            ),
          ),
        ),
      );

  @override
  Future<List<CommercialLine>> getAll() => _all();

  @override
  Future<CommercialLine?> getById(String id) async {
    for (final line in await _all()) {
      if (line.id == id) return line;
    }
    return null;
  }

  @override
  Future<List<CommercialLine>> search(String query) async {
    final needle = query.trim().toLowerCase();
    return List.unmodifiable(
      (await _all())
          .where(
            (line) =>
                needle.isEmpty || line.nombre.toLowerCase().contains(needle),
          )
          .toList(growable: false),
    );
  }
}

final class AssetProductRepository implements ProductRepository {
  AssetProductRepository(this._loader);

  final AssetCatalogLoader _loader;
  Future<List<CommercialLine>>? _linesCache;
  Future<List<CatalogProduct>>? _productsCache;

  Future<List<CommercialLine>> _lines() => _linesCache ??= _loader
      .validateManifest()
      .then((_) => _loader.items(AssetCatalogLoader.linesPath))
      .then(
        (items) => List.unmodifiable(
          items.map(
            (item) => CommercialLine(
              id: _text(item, 'id'),
              nombre: _text(item, 'name'),
            ),
          ),
        ),
      );

  Future<List<CatalogProduct>> _products() => _productsCache ??=
      Future.wait([
        _lines(),
        _loader.items(AssetCatalogLoader.productsPath),
      ]).then((values) {
        final lines = values[0] as List<CommercialLine>;
        final rawProducts = values[1] as List<Map<String, Object?>>;
        final lineById = {for (final line in lines) line.id: line};
        final products = <CatalogProduct>[];
        for (final item in rawProducts) {
          final line = lineById[item['lineId']];
          if (line == null) {
            throw const CatalogLoadException(
              'Un producto IA1 tiene una línea inexistente.',
            );
          }
          products.add(
            CatalogProduct(
              id: _text(item, 'id'),
              codigo: '',
              nombre: _text(item, 'name'),
              descripcion: '',
              linea: line,
              presentacion: '',
              precio: 0,
              categoria: '',
              hasVerifiedCode: false,
              hasVerifiedPrice: false,
              hasVerifiedPresentation: false,
              hasVerifiedCategory: false,
            ),
          );
        }
        return List.unmodifiable(products);
      });

  @override
  Future<List<CommercialLine>> getLines() => _lines();

  @override
  Future<List<CatalogProduct>> getProducts({
    String? lineId,
    String query = '',
  }) async {
    final needle = query.trim().toLowerCase();
    return List.unmodifiable(
      (await _products())
          .where(
            (product) =>
                (lineId == null ||
                    lineId.isEmpty ||
                    product.linea.id == lineId) &&
                (needle.isEmpty ||
                    product.nombre.toLowerCase().contains(needle)),
          )
          .toList(growable: false),
    );
  }
}

final class AssetComodatoRepository implements ComodatoRepository {
  AssetComodatoRepository(this._loader);

  final AssetCatalogLoader _loader;
  Future<List<Comodato>>? _cache;

  Future<List<Comodato>> _all() => _cache ??= _loader
      .validateManifest()
      .then((_) => _loader.items(AssetCatalogLoader.comodatosPath))
      .then(
        (items) => List.unmodifiable(
          items.map(
            (item) => Comodato(
              id: _text(item, 'id'),
              codigo: _text(item, 'code'),
              nombre: _text(item, 'name'),
              esGeneral: item['isGeneral'] == true,
            ),
          ),
        ),
      );

  @override
  Future<List<Comodato>> getAll() => _all();

  @override
  Future<Comodato?> getById(String id) async {
    for (final comodato in await _all()) {
      if (comodato.id == id) return comodato;
    }
    return null;
  }

  @override
  Future<List<Comodato>> search(String query) async {
    final needle = query.trim().toLowerCase();
    return List.unmodifiable(
      (await _all())
          .where(
            (comodato) =>
                needle.isEmpty ||
                comodato.codigo.toLowerCase().contains(needle) ||
                comodato.nombre.toLowerCase().contains(needle),
          )
          .toList(growable: false),
    );
  }
}

String _text(Map<String, Object?> item, String key) {
  final value = item[key];
  if (value is String && value.trim().isNotEmpty) return value;
  throw CatalogLoadException('Falta $key en un item de catálogo.');
}
