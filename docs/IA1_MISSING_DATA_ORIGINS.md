# Origen de datos faltantes IA1

Auditoría de solo lectura del Desktop en
`e238e4788e40d96c7d3f2387dcc60d51123159b0`. No se modificó el repositorio
Desktop ni se importaron valores a Mobile.

## Evidencia revisada

- `AutoDataClientes.xlsx`: hojas visibles `Resumen` y `Clientes`; el maestro
  útil solo contiene `orden` y `cliente`.
- `AutoDataProductos.xlsx`: hojas visibles `Resumen`, `LineasPedido` y
  `ProductosPorLinea`; esta última solo contiene `orden_linea`,
  `linea_pedido`, `orden_producto` y `producto`.
- `AutomyDataMineOtro.xlsx`: opciones de listas, no valores por producto.
- No hay hojas ni columnas ocultas en esos tres orígenes. El generador
  `tools/embed_catalogs.py:20-90` solo extrae cliente, línea, producto y listas.
- `models/product.py:7-41` define campos de una fila de pedido. En particular,
  `precio_unitario` es `PRECIO UNITARIO`, mientras `codigo_producto` se rotula
  `COMODATO`; no es un código comercial de producto.
- `services/excel_service.py:61-107` escribe esos valores ya introducidos a
  `VALOR UNITARIO` y `COMODATO` en el Excel que se carga a Automy.
- `automation/workflow.py:75-109` importa el Excel y selecciona la institución;
  Selenium consume valores y no obtiene un maestro de vuelta.
- Los perfiles se guardan bajo `%LOCALAPPDATA%/InterAutomy/profiles`; los datos
  locales por cliente se guardan en `client_profiles.json` y el historial en
  `execution_history.sqlite3` (`app/paths.py:39-64`,
  `ui/main_window.py:123-125`).
- `samples/Prueba.json` demuestra datos de ejemplo dentro de un perfil, no un
  maestro: contiene precios, presentación, categoría, comodato, institución y
  relación `enlaces_clientes`.
- `samples/envio/DataBaseEnvio.xlsx` y `Cuadroo.xlsx` contienen historia de
  envíos (`PreUnit`, `CodProd`, `CodEqv`) y una hoja oculta de reporte. No son
  fuentes IA1 usadas por `CatalogService` y no acreditan vigencia comercial.

## Respuestas

| Pregunta | Clasificación | Evidencia y conclusión |
|---|---|---|
| ¿De dónde sale el precio? | `PROFILE_BASED` | Se escribe manualmente en cada `Product`, se persiste en perfil/historial y luego pasa al Excel. El maestro IA1 no lo contiene. Los precios históricos de envíos no se consideran tarifa vigente. |
| ¿De dónde sale el código comercial? | `REQUIRES_USER_SOURCE` | IA1 incluye prefijos dentro del texto del producto, pero no un campo comercial verificado. `codigo_producto` del Desktop significa comodato. `CodProd/CodEqv` solo aparece en datos históricos del módulo de envíos. Hace falta un maestro autorizado y una regla de correspondencia. |
| ¿Dónde se guardan instituciones? | `PROFILE_BASED` | En `OrderParams.cliente_institucional`, perfiles JSON, `client_profiles.json` y filtros `enlaces_clientes`; no existe maestro IA1 versionado. |
| ¿Dónde se guardan comodatos? | `PROFILE_BASED` | En `ClientProfile.allowed_comodatos_by_line`, perfiles JSON, `client_profiles.json` y snapshots del historial. |
| ¿Son datos maestros o de perfil? | `PROFILE_BASED` | En IA1, instituciones, relaciones y comodatos son configuración local de perfil. Precio/presentación/categoría también son valores de fila de pedido. |
| ¿Hay relación cliente–institución? | `PROFILE_BASED` | Sí, en el campo del cliente y en `filters.enlaces_clientes`; no existe una tabla maestra global. |
| ¿Qué campos no están disponibles? | `NOT_PRESENT` | Precio vigente, código comercial separado/verificado, presentación por producto, categoría por producto, expiración por producto, maestro de instituciones y maestro cliente–línea–comodato. |
| ¿Qué debe aportar el usuario? | `REQUIRES_USER_SOURCE` | Maestro autorizado de códigos/precios/presentaciones/categorías con fecha o versión; instituciones y relaciones cliente–institución; comodatos permitidos por cliente y línea. |

## Datos derivados y límites

- Línea y nombre del producto: `FOUND` en los Excel IA1.
- IDs Mobile: `DERIVED` de nombres normalizados mediante SHA-256 estable; no
  son códigos comerciales.
- Prefijo aparente al inicio del nombre: `DERIVED`, pero no se separa ni se
  marca verificado porque no hay contrato que garantice su semántica.
- Institución seleccionada durante Selenium: `RUNTIME_ONLY`; es entrada del
  perfil, no descubrimiento de un catálogo.
- Valores de `samples/Prueba.json`: `PROFILE_BASED` y de muestra; no deben
  generalizarse ni copiarse como maestros.

## Fuente mínima requerida

Un archivo entregado por el responsable comercial debería incluir al menos
`productId/sourceName`, `commercialCode`, `price`, `currency`, `validFrom`,
`presentation` y `category`; otro debería definir `client`, `institution` y
comodatos permitidos por línea. Hasta recibirlos, IA1 se mantiene consultable
pero no ejecutable.
