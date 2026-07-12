# Referencia del proyecto de escritorio IA1

## Versión analizada

- Repositorio: `InterAutomy` (solo lectura).
- Commit: `e238e4788e40d96c7d3f2387dcc60d51123159b0`.
- Mensaje: `IA1`.
- La copia de trabajo estaba en ese commit; no se modificó.

## Arquitectura observada

El programa desktop separa el arranque y las rutas (`app`), los modelos de
pedido (`models`), las reglas y persistencia (`services`), la automatización web
(`automation`) y la interfaz Qt (`ui`). El flujo principal convierte los
controles en parámetros y productos, valida en un servicio compartido, genera
un archivo de intercambio, ejecuta un worker y presenta el resultado explícito
del flujo web.

La persistencia de perfiles e historial usa documentos JSON versionados. Los
catálogos proceden de libros Excel y se empaquetan como datos embebidos. La
ejecución usa resultados tipados para distinguir éxito, error, cancelación,
expiración y revisión manual.

## Módulos y funcionalidades principales

- `models`: parámetros de orden, filas de producto, perfiles por cliente y
  registros de envíos.
- `services.validation_service`: validaciones por campo y por fila antes de
  ejecutar.
- `services.client_profile_service`: clientes, selección activa y comodatos.
- `services.comodato_service`: selección y verificación del comodato según el
  cliente y la línea comercial.
- `services.history_service`: historial con snapshot de productos y búsqueda.
- `services.catalog_service`: consulta de líneas y productos.
- `services.excel_service`: intercambio con el portal mediante un libro
  generado.
- `services.automy_runner` y `automation`: sesión de Chrome, pasos Selenium,
  bitácora y resultado final.
- `ui.main_window`: coordinación de formularios, productos, ejecución,
  restauración y mensajes.

## Reglas de negocio relevantes

- Un pedido se valida antes de generar datos o iniciar la automatización.
- Los campos requeridos del producto incluyen línea, producto, presentación,
  precio, cantidad, categoría y comodato cuando corresponde.
- Precio y cantidad deben ser valores numéricos válidos y positivos.
- Los nombres y códigos se normalizan eliminando espacios; las comparaciones
  que evitan duplicados no distinguen mayúsculas.
- Los comodatos se almacenan por cliente y línea, conservando una categoría
  general para perfiles heredados.
- La resolución de comodato prioriza el valor explícito; después usa el único
  valor permitido para la línea y finalmente el general. Si no existe un valor
  válido, la ejecución debe advertirlo.
- El historial conserva fecha, hora, cliente, línea, resultado y snapshot de
  productos. Puede restaurar una línea o la ejecución completa.
- Al agregar productos restaurados se detectan duplicados y se ofrece sumar
  cantidades; también se permite reemplazar o cancelar.
- Con AutoValidación desactivada, la automatización se detiene antes de
  completar el pedido y exige revisión manual. Con AutoValidación activada,
  completa el paso final automáticamente.
- El éxito no se deduce de la ausencia de excepciones: cada paso debe devolver
  una confirmación y el workflow produce un resultado final explícito.

## Flujo de datos

1. La interfaz reúne cliente, orden y productos.
2. Los servicios aplican valores predeterminados de comodato y validan.
3. Desktop genera el Excel requerido por Automy.
4. Un worker inicia Chrome y ejecuta pasos trazables de Selenium.
5. En revisión manual, el usuario confirma el envío y cierra Chrome.
6. Se registra el resultado y el snapshot en historial.

## Adaptación Desktop vs. Mobile

| Desktop IA1 | Aplicación móvil |
| --- | --- |
| Ventana Qt y tablas editables | Material 3, tarjetas, formularios y navegación táctil |
| Archivos Excel como catálogos e intercambio | Catálogo demo local y DTOs para una API futura |
| JSON en el sistema de archivos | Repositorios intercambiables y preferencias locales |
| Selenium y ChromeDriver locales | Gateway remoto; simulación segura en modo demo |
| Worker `QThread` y señales Qt | Estado reactivo y streams de progreso |
| Diálogos con tamaño de escritorio | Diálogos, hojas inferiores y layouts responsive |
| Credenciales/sesión del Chrome local | Tokens futuros en almacenamiento seguro, sin secretos reales |

## Conceptos reutilizables

- Entidades de cliente, producto, pedido, ejecución e historial.
- Validaciones deterministas fuera de la interfaz.
- Resolución de comodatos por cliente y línea.
- Snapshots completos para restaurar envíos.
- Estados explícitos, progreso, bitácora y errores controlados.
- Separación entre catálogo, perfiles, historial y automatización.
- Modo de revisión humana antes de confirmar un envío.

## Componentes no portables

No se trasladan PySide6, QFluentWidgets, señales Qt, `QThread`, escalado de
ventanas, diálogos Qt, Selenium, ChromeDriver, perfiles de Chrome, archivos
Excel, rutas de Windows, ejecutables, keyring ni procesos locales. Tampoco se
incluyen los módulos de Mercado/SEACE, porque no forman parte del MVP móvil de
pedidos solicitado.

## Decisiones para móvil

- Mantener dominio puro Dart y contratos de repositorio independientes de la
  UI.
- Activar un modo demo por defecto con datos reproducibles y duraciones
  configurables.
- Representar el agente Windows mediante un `AutomationGateway`; la app no
  ejecuta automatización local.
- Preparar Dio y DTOs, dejando repositorios remotos desactivados hasta disponer
  de una API real.
- Centralizar el estado para preservar el formulario y los productos al
  cambiar de sección.
- Tratar la revisión humana como un estado de ejecución, no como un diálogo
  bloqueante del sistema operativo.

## Riesgos

- La API, autenticación y protocolo con el agente Windows todavía no existen;
  no es posible validar una ejecución real desde móvil.
- Los catálogos demo no sustituyen los maestros empresariales ni su proceso de
  actualización.
- La migración de perfiles e historial desktop requerirá un contrato de datos y
  reglas de compatibilidad antes de producción.
- La aplicación deberá manejar pérdida de red, reintentos e idempotencia cuando
  las ejecuciones sean remotas.
- La confirmación manual debe diseñarse con auditoría y autorización del lado
  servidor para evitar dobles envíos.
