# Modelo de dominio móvil consolidado

## Estado actual

La consolidación es incremental para conservar el flujo existente y evitar una
migración destructiva. El dominio no depende de Flutter ni del WebView.

```text
AppSettings ──> selección Demo/WebView y fuente de catálogo
Client + Comodato ──> Order ──> Execution ──> HistoryRecord
CatalogProduct ──> SelectedProduct ─┘
CommercialLine ────────────────────┘
Institution (entidad seleccionable y persistida desde Cliente)
```

| Concepto | Representación actual | Estado |
| --- | --- | --- |
| Cliente | `Client` | Disponible; hoy contiene temporalmente ubicación, contacto, OC y condiciones. |
| Institución | `Institution` | Entidad, contrato y overlay persistente disponibles; Cliente permite seleccionar, crear y editar. |
| Línea comercial | `CommercialLine` | Disponible desde Demo o assets IA1. |
| Producto de catálogo | `CatalogProduct` | Disponible; conserva banderas de campos verificables. |
| Producto de pedido | `SelectedProduct` | Disponible; contiene cantidad, precio, comodato, expiración y subtotal. |
| Comodato | `Comodato` | Disponible; se resuelve con un servicio de dominio. |
| Pedido | `Order` | Disponible para iniciar ejecución. |
| Ejecución | `Execution` y sus estados | Disponible para Demo/WebView. |
| Historial | `HistoryRecord` | Snapshot inmutable de cliente/productos, modo y total; se persiste localmente. |
| Perfil | `OrderProfile` | Snapshot local reutilizable de cliente y productos, con repositorio persistente. |
| Ajustes | `AppSettings` | Disponible y persistido como preferencias simples. |

## Servicios y límites de responsabilidad

| Componente | Responsabilidad |
| --- | --- |
| `SettingsController` | Carga y guarda preferencias simples; no conoce ejecución ni gateways. |
| `AppController` | Orquesta catálogo, pedido, ejecución, restauración, perfiles e instituciones durante la transición. |
| `OrderValidationService` | Produce incidencias tipadas sin depender de widgets. |
| `ComodatoResolutionService` | Aplica la prioridad IA1 de comodato sin escoger uno arbitrariamente. |
| Repositorios Demo/asset/overlay | Separan Demo e IA1 y combinan el catálogo inmutable con registros locales. |
| `LocalDomainStore` | Documento JSON privado `schemaVersion: 1`, escritura mediante archivo temporal y migración de v0 para colecciones complejas. |
| `AutomationGateway` | Abstrae Demo o WebView y no vuelve a leer `AppController`. |

No existen todavía `ClientController`, `OrderController`, `ExecutionController`
e `HistoryController` separados. La persistencia ya está disponible, pero esa
separación sigue siendo conveniente para reducir el alcance de `AppController`.

## Decisión de persistencia local

Se evaluó Drift para clientes personalizados, instituciones, perfiles, pedidos
e historial. No se incorporó en esta fase porque el proyecto no tenía una base
de datos ni generación de código previa, y migrar simultáneamente todos los
modelos heredados habría ampliado el alcance de la corrección del ciclo de
providers. En su lugar, `LocalDomainStore` ofrece un documento estructurado
privado con `schemaVersion: 1`, backend inyectable y migración v0 comprobada.

Esta no es una implementación de Drift ni una migración SQLite equivalente al
historial Desktop. La siguiente fase debe decidir si conserva este formato o
lo migra una sola vez a Drift, con una migración de datos ensayada antes de
habilitar relaciones complejas adicionales.

## Campos aún agrupados y value objects pendientes

`Client` mantiene como adaptación temporal institución, ubicación, contacto,
orden de compra y condiciones comerciales en campos escalares. Aún no hay value
objects para `ClientId`, `InstitutionId`, `ProductCode`, dinero, cantidad,
teléfono u orden de compra. Tampoco existen entidades móviles separadas para
`Location`, `Contact`, `PurchaseOrder`, `CommercialConditions`,
`ExecutionLogEntry` o `Profile`.

El almacenamiento local ya tiene `schemaVersion: 1` y una migración v0; futuras
descomposiciones deben extender esas migraciones sin perder borradores, perfiles
ni historial. La ausencia de esos value objects no debe ocultarse como una
consolidación finalizada.

## Invariantes presentes

- El catálogo IA1 es de solo lectura y no hace fallback silencioso a Demo.
- Los detalles ausentes del catálogo se marcan como no verificados.
- El historial conserva productos del momento de ejecución, no vuelve a
  consultar el catálogo para reconstruirlos.
- Configuración → gateway → controlador es una dirección de dependencia; el
  gateway no puede depender de `AppController`.
