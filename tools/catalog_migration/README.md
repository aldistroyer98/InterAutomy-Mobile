# Migración de catálogos IA1

Esta herramienta de desarrollo convierte únicamente los maestros versionados de
IA1 a JSON para Flutter. Nunca modifica los Excel ni se empaqueta en Android.

```powershell
python tools/catalog_migration/migrate_ia1_catalogs.py `
  --desktop-root C:\ruta\al\checkout\InterAutomy `
  --generated-at 2026-07-12T00:00:00Z
```

Entradas requeridas en `--desktop-root`:

- `AutoDataClientes.xlsx`
- `AutoDataProductos.xlsx`
- `AutomyDataMineOtro.xlsx`

Salidas: `assets/catalogs/*.json`. Los IDs son hashes estables de valores
normalizados, no códigos comerciales. La herramienta falla ante valores
obligatorios vacíos, duplicados o relaciones línea-producto inválidas.

Los maestros no contienen instituciones, comodatos por cliente/línea, precios,
presentación, categoría, expiración ni códigos de producto independientes. Esos
campos se dejan ausentes y se reportan en el manifiesto; no se infieren.

## Validar assets versionados

La validación no requiere los Excel ni `openpyxl`; se ejecuta tanto localmente
como en CI:

```powershell
python tools/catalog_migration/validate_catalog_assets.py
```

Comprueba JSON, `schemaVersion`, fuente, manifiesto, opciones, conteos, IDs
únicos, relaciones producto–línea, referencias opcionales de comodato y el
checksum de los cinco catálogos. No publica archivos Excel ni modifica assets.
El checksum canoniza LF/CRLF para representar el mismo contenido en Windows y
en los runners Linux de CI.

## Auditar completitud y readiness

El auditor es de solo lectura y produce evidencia JSON y Markdown bajo
`build/reports/`:

```powershell
python tools/catalog_migration/audit_catalog_quality.py
python -m unittest tools.catalog_migration.test_audit_catalog_quality -v
```

Reporta totales, porcentajes incompletos, duplicados, relaciones inválidas y la
disponibilidad explícita de precio, código comercial, institución y comodato.
No rellena campos ausentes ni convierte IDs técnicos en códigos comerciales.
