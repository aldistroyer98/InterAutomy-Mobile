# Matriz de paridad Desktop IA1 – Mobile

Referencia Desktop analizada en solo lectura: `e238e4788e40d96c7d3f2387dcc60d51123159b0` (`IA1`).
Los estados describen el árbol móvil de esta fase, no una promesa de paridad.

| Área | Función IA1 | Estado móvil actual | Diferencia | Acción |
| --- | --- | --- | --- | --- |
| Cliente | Buscar, seleccionar, crear, editar y guardar | PARTIAL | Hay selector, borrador, edición, descarte y overlay persistente sobre Demo/IA1. Falta detección visual de cambios sin guardar y búsqueda dedicada. | Completar controles de cambios y experiencia IA1. |
| Institución | Entidad asociable con ubicación y contacto | PARTIAL | Existe entidad, repositorio overlay, validación de duplicado, persistencia y selector/creación/edición desde Cliente. El catálogo IA1 contiene 0; faltan búsqueda y gestión independiente completa. | Añadir búsqueda, baja y vista de gestión dedicada. |
| Orden de compra | Número y motivo | PARTIAL | Campos disponibles y validados como NRO OC o motivo. | Consolidar objeto de orden de compra y reglas de edición. |
| Archivo OC | Seleccionar, cambiar, abrir y quitar archivo local | IMPLEMENTED | Cliente usa SAF para PDF, imagen o documento y conserva URI, nombre y MIME; puede elegir, abrir, cambiar y quitar sin cargar a Automy. | Validar permisos persistibles y tipos en Galaxy A26. |
| Ubicación | Departamento, provincia, distrito y dirección | PARTIAL | Campos de texto y validación de presencia. | Asociarlos a Institution y validar catálogos/reglas reales cuando existan. |
| Contacto | Contacto y teléfono | PARTIAL | Campos y validación mínima de teléfono. | Persistir por institución y cubrir reglas de formato aprobadas. |
| Condiciones comerciales | Unidad, servicio, horarios, IGV, moneda, adelanto y motivo | PARTIAL | Campos principales disponibles; no todas las condiciones tienen validación semántica. | Extraer value objects y reglas completas de IA1. |
| Comentario final | Conservar y validar comentario | PARTIAL | Campo disponible y obligatorio en validación. | Construir el formato final solo con reglas IA1 comprobadas. |
| Línea comercial | Catálogo y filtrado | IMPLEMENTED | Las 62 líneas IA1 se cargan desde assets y filtran productos. | Mantener regeneración y validación de assets. |
| Producto | Buscar, filtrar, agregar, editar, cantidad y eliminar | PARTIAL | La relación IA1 línea-producto está disponible; faltan maestros de atributos comerciales. | Incorporar solo fuentes autorizadas de atributos faltantes. |
| Precio | Precio autorizado y total | PARTIAL | Demo incluye precio; IA1 no lo aporta y el validador impide ejecutar sin precio verificable. | Importar un maestro autorizado o capturar/validar precio localmente. |
| Cantidad | Cantidad positiva y acumulación | IMPLEMENTED | Se controla en productos, validación y restauración. | Mantener pruebas de límites y duplicados. |
| Categoría | Categoría por producto | MISSING | IA1 versionado no contiene ese atributo. | No inferirla; añadir fuente aprobada. |
| Presentación | Presentación por producto | MISSING | IA1 versionado no contiene ese atributo. | No inferirla; añadir fuente aprobada. |
| Comodato | General, por línea, explícito y resolución | PARTIAL | Servicio de prioridad y opciones de selección disponibles con datos Demo. No hay maestro IA1 ni gestión/persistencia completa. | Implementar repositorio local, CRUD y asociación cliente–línea. |
| Expiración | Fecha por producto | MISSING | La fuente IA1 no contiene expiración. | Incorporar fuente autorizada antes de habilitarla. |
| Validación | Reglas de pedido antes de ejecutar | PARTIAL | `OrderValidationService` devuelve incidencias tipadas y hay diálogo previo. Faltan reglas comerciales profundas. | Ampliar mediante servicios de dominio y pruebas IA1. |
| Ejecución | Flujo con estado y revisión | PARTIAL | Demo cubre ejecución, revisión, confirmación y errores amigables. WebView conserva infraestructura, sin flujo real ampliado. | Validar manualmente en Android; no ampliar Automy real en esta fase. |
| AutoValidación | Confirmación/avance configurable | MISSING | No existe una preferencia equivalente separada. | Definir contrato y autorización antes de automatizar cualquier paso. |
| Bitácora | Eventos trazables de ejecución | PARTIAL | La ejecución mantiene progreso y resultados; no hay bitácora local persistente completa. | Diseñar almacenamiento de eventos con privacidad. |
| Historial | Buscar, detalle, snapshot y restauración | PARTIAL | Se persiste localmente, conserva snapshot de cliente/productos/modo/total, muestra modo/total/resultado y permite borrar con confirmación. Solo se registran ejecuciones completadas; falta política para intentos no completados. | Definir y probar la política de eventos no completados. |
| Restauración | Agregar o reemplazar pedido | PARTIAL | La restauración suma duplicados o reemplaza productos y usa el snapshot de cliente si ya no está cargado. | Añadir confirmación explícita de cambio de cliente en UI. |
| Perfiles | Guardar, cargar, duplicar, renombrar y eliminar | PARTIAL | Entidad y repositorio persistentes, más UI en Cliente para guardar, cargar, renombrar, duplicar y eliminar. Falta indicador de cambios sin guardar y pruebas del ciclo completo. | Añadir estado modificado y cobertura de widget/integración. |
| Catálogos | Maestros de clientes, líneas y productos | IMPLEMENTED | Fuente Demo e IA1 seleccionables; manifiesto, checksum y relaciones se validan. | Incorporar fuentes faltantes sin fallback silencioso. |
| Mercado | Módulo Mercado/SEACE | OUT_OF_SCOPE | No hay navegación ni automatización móvil de Mercado. | Requiere una decisión de producto independiente. |
| Reportes | Reportes operativos de escritorio | OUT_OF_SCOPE | No hay motor ni UI de reportes en móvil. | Definir necesidades, privacidad y formato antes de incluirlo. |

`IMPLEMENTED` significa que el alcance específico de la fila está disponible;
no implica que todos los datos empresariales estén disponibles. `PARTIAL` y
`MISSING` no deben presentarse como paridad de IA1.
