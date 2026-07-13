# Informe de migración del catálogo IA1

## Referencia y resultado reproducible

| Dato | Valor |
| --- | --- |
| Commit Desktop fuente | `e238e4788e40d96c7d3f2387dcc60d51123159b0` (`IA1`) |
| Esquema | `1` |
| Generado UTC | `2026-07-13T05:19:33Z` |
| Checksum del manifiesto | `7ba838e32ee79cae0fc575ed7e9fba1ae3cdedf8ae4d67ce85f4564ceffeaad2` |
| Errores de ejecución de la migración | `0`; el generador terminó sin excepción |

| Asset | Registros |
| --- | ---: |
| `clients.json` | 3 128 |
| `institutions.json` | 0 |
| `commercial_lines.json` | 62 |
| `products.json` | 8 838 |
| `comodatos.json` | 0 |

La ausencia de instituciones y comodatos no es un error de conversión: los
maestros IA1 versionados examinados no contenían esos registros. Un conteo cero
no debe interpretarse como que la organización no posea instituciones o
comodatos fuera de esos archivos.

## Fuentes leídas sin modificarlas

| Libro IA1 | Hoja | Datos exportados |
| --- | --- | --- |
| `AutoDataClientes.xlsx` | `Clientes` | Nombres de cliente normalizados y su identificador estable. |
| `AutoDataProductos.xlsx` | `LineasPedido` | Líneas comerciales. |
| `AutoDataProductos.xlsx` | `ProductosPorLinea` | Pares únicos línea–producto. |
| `AutomyDataMineOtro.xlsx` | `Listas` | Opciones comprobables incluidas en `catalog_manifest.json`. |

Los IDs JSON son hashes estables derivados de texto normalizado; no son códigos
comerciales ni identificadores que puedan mostrarse como tales.

## Datos deliberadamente no inventados

La fuente no aportó por producto precios, códigos comerciales, presentación,
categoría ni expiración. Tampoco aportó maestros versionados para instituciones
ni comodatos por cliente/línea. Los repositorios de assets exponen esos campos
como no verificados o catálogos vacíos; el flujo no los rellena con valores
ficticios.

El valor llamado `codigo_producto` encontrado para comodatos en Desktop no se
trata como código de catálogo de producto: su semántica es de comodato y no se
exporta como atributo de producto.

## Garantías de la herramienta

`tools/catalog_migration/migrate_ia1_catalogs.py`:

1. lee los Excel en modo solo lectura;
2. normaliza Unicode y espacios, preservando acentos;
3. rechaza campos obligatorios vacíos, duplicados y pares línea-producto
   inválidos;
4. ordena las salidas y calcula un checksum determinista;
5. escribe únicamente `assets/catalogs/*.json`;
6. no se empaqueta en Android.

La comprobación de CI ejecuta
`python tools/catalog_migration/validate_catalog_assets.py`. Verifica JSON,
esquema/manifiesto, conteos, IDs únicos, campos mínimos, relaciones de producto
con línea y checksum. No necesita ni publica los Excel fuente.

## Regeneración autorizada

Desde un checkout local del Desktop en el commit de referencia:

```powershell
$generatedAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
python tools/catalog_migration/migrate_ia1_catalogs.py `
  --desktop-root C:\ruta\al\checkout\InterAutomy `
  --generated-at $generatedAt
python tools/catalog_migration/validate_catalog_assets.py
```

La regeneración debe revisarse como cambio de datos: confirmar commit de origen,
conteos, checksum y diferencias antes de incorporarla. No se modifica el
repositorio Desktop ni se suben sus Excel como artefactos de CI.
