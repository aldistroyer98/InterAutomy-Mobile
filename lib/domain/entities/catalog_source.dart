enum CatalogSource { demo, ia1 }

extension CatalogSourceLabel on CatalogSource {
  String get label => switch (this) {
    CatalogSource.demo => 'Demo',
    CatalogSource.ia1 => 'Catalogo IA1',
  };
}
