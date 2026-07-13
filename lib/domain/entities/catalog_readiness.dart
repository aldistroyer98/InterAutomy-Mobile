/// Estado principal que explica por qué una entidad de catálogo no está lista.
///
/// [missingFields] en cada entidad conserva el detalle completo cuando faltan
/// varios datos; este enum ofrece una causa estable y tipada para UI y pruebas.
enum CatalogReadiness {
  complete,
  missingPrice,
  missingCommercialCode,
  missingLine,
  missingPresentation,
  missingCategory,
  missingInstitution,
  missingComodatoMetadata,
  notExecutable,
}

extension CatalogReadinessPresentation on CatalogReadiness {
  String get statusLabel => switch (this) {
    CatalogReadiness.complete => 'Completo',
    CatalogReadiness.notExecutable => 'No apto para ejecución',
    _ => 'Incompleto',
  };

  String get reasonLabel => switch (this) {
    CatalogReadiness.complete => 'Datos completos',
    CatalogReadiness.missingPrice => 'Falta precio verificado',
    CatalogReadiness.missingCommercialCode =>
      'Falta código comercial verificado',
    CatalogReadiness.missingLine => 'Falta línea comercial',
    CatalogReadiness.missingPresentation => 'Falta presentación',
    CatalogReadiness.missingCategory => 'Falta categoría',
    CatalogReadiness.missingInstitution => 'Falta institución',
    CatalogReadiness.missingComodatoMetadata =>
      'Falta relación de comodato válida',
    CatalogReadiness.notExecutable => 'Datos base no ejecutables',
  };
}
