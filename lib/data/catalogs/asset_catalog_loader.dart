import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

final class CatalogLoadException implements Exception {
  const CatalogLoadException(this.message, {this.details});

  static const code = 'CATALOG_LOAD_FAILED';

  final String message;
  final String? details;

  @override
  String toString() => '$code: $message';
}

final class CatalogManifest {
  const CatalogManifest({
    required this.sourceDesktopCommit,
    required this.generatedAt,
    required this.clients,
    required this.institutions,
    required this.lines,
    required this.products,
    required this.comodatos,
    required this.checksum,
  });

  final String sourceDesktopCommit;
  final String generatedAt;
  final int clients;
  final int institutions;
  final int lines;
  final int products;
  final int comodatos;
  final String checksum;
}

/// Carga los JSON de assets una sola vez y valida forma, identidad y manifiesto.
final class AssetCatalogLoader {
  AssetCatalogLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const clientsPath = 'assets/catalogs/clients.json';
  static const institutionsPath = 'assets/catalogs/institutions.json';
  static const linesPath = 'assets/catalogs/commercial_lines.json';
  static const productsPath = 'assets/catalogs/products.json';
  static const comodatosPath = 'assets/catalogs/comodatos.json';
  static const manifestPath = 'assets/catalogs/catalog_manifest.json';

  final AssetBundle _bundle;
  final Map<String, Future<List<Map<String, Object?>>>> _itemsCache = {};
  Future<CatalogManifest>? _manifestCache;

  Future<List<Map<String, Object?>>> items(String path) =>
      _itemsCache.putIfAbsent(path, () => _readItems(path));

  Future<CatalogManifest> manifest() => _manifestCache ??= _readManifest();

  Future<CatalogManifest> validateManifest() async {
    final manifest = await this.manifest();
    final paths = <String>[
      clientsPath,
      institutionsPath,
      linesPath,
      productsPath,
      comodatosPath,
    ];
    final entries =
        (await Future.wait(
          paths.map((path) async => (path, await _bundle.load(path))),
        )).toList()..sort(
          (left, right) =>
              left.$1.split('/').last.compareTo(right.$1.split('/').last),
        );
    final checksumBytes = <int>[];
    for (final (path, bytes) in entries) {
      checksumBytes.addAll(utf8.encode(path.split('/').last));
      checksumBytes.add(0);
      checksumBytes.addAll(_canonicalTextBytes(bytes));
      checksumBytes.add(0);
    }
    final checksum = sha256.convert(checksumBytes).toString();
    if (checksum != manifest.checksum) {
      throw const CatalogLoadException(
        'El manifiesto de catálogo no coincide con sus assets.',
      );
    }
    final counts = await Future.wait(paths.map(items));
    final actual = counts.map((value) => value.length).toList(growable: false);
    if (actual[0] != manifest.clients ||
        actual[1] != manifest.institutions ||
        actual[2] != manifest.lines ||
        actual[3] != manifest.products ||
        actual[4] != manifest.comodatos) {
      throw const CatalogLoadException(
        'Las cantidades del manifiesto de catálogo no coinciden.',
      );
    }
    return manifest;
  }

  Future<List<Map<String, Object?>>> _readItems(String path) async {
    final decoded = await _decodeObject(path);
    final rawItems = decoded['items'];
    if (rawItems is! List) {
      throw CatalogLoadException('$path no contiene una lista de items.');
    }
    final ids = <String>{};
    final values = <Map<String, Object?>>[];
    for (final raw in rawItems) {
      if (raw is! Map) {
        throw CatalogLoadException('$path contiene un item inválido.');
      }
      final item = Map<String, Object?>.from(raw);
      final id = item['id'];
      if (id is! String || id.trim().isEmpty || !ids.add(id)) {
        throw CatalogLoadException('$path contiene IDs vacíos o duplicados.');
      }
      values.add(Map.unmodifiable(item));
    }
    return List.unmodifiable(values);
  }

  Future<CatalogManifest> _readManifest() async {
    final decoded = await _decodeObject(manifestPath);
    int count(String key) {
      final value = decoded[key];
      if (value is int && value >= 0) return value;
      throw CatalogLoadException('El manifiesto tiene $key inválido.');
    }

    String text(String key) {
      final value = decoded[key];
      if (value is String && value.trim().isNotEmpty) return value;
      throw CatalogLoadException('El manifiesto tiene $key inválido.');
    }

    return CatalogManifest(
      sourceDesktopCommit: text('sourceDesktopCommit'),
      generatedAt: text('generatedAt'),
      clients: count('clients'),
      institutions: count('institutions'),
      lines: count('lines'),
      products: count('products'),
      comodatos: count('comodatos'),
      checksum: text('checksum'),
    );
  }

  Future<Map<String, Object?>> _decodeObject(String path) async {
    try {
      final decoded = jsonDecode(await _bundle.loadString(path));
      if (decoded is! Map) {
        throw CatalogLoadException('$path no contiene un objeto JSON.');
      }
      return Map<String, Object?>.from(decoded);
    } on CatalogLoadException {
      rethrow;
    } on Object catch (error) {
      throw CatalogLoadException('No se pudo cargar $path.', details: '$error');
    }
  }

  static List<int> _bytes(ByteData data) =>
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

  static List<int> _canonicalTextBytes(ByteData data) => utf8.encode(
    utf8.decode(_bytes(data)).replaceAll('\r\n', '\n').replaceAll('\r', '\n'),
  );
}
