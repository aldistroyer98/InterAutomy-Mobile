# Arquitectura móvil

## Objetivos

La aplicación separa reglas de negocio, infraestructura y presentación para
mantener el modo demo intercambiable por una API. La solución evita generación
de código innecesaria y usa entidades inmutables escritas en Dart.

## Capas

### App

Configura Material 3, tema, rutas y parámetros globales. `StatefulShellRoute`
mantiene cinco ramas vivas: cliente, productos, ejecución, historial y ajustes.

### Core

Contiene errores tipados, breakpoints, el cliente Dio, endpoints y componentes
responsive. Los breakpoints son: compacto menor a 600, mediano de 600 a 839 y
expandido desde 840.

### Domain

No depende de Flutter. Incluye Client, CommercialLine, Comodato,
CatalogProduct, SelectedProduct, Order, Execution, HistoryRecord,
ExecutionLogEntry y AppSettings. Los validadores y la resolución de comodato se
ejecutan fuera de widgets.

### Data

Implementa los contratos. Los repositorios demo viven en memoria; las
preferencias usan almacenamiento local. Los repositorios remotos existen como
frontera desactivada y fallan con un error controlado si alguien intenta usarlos
antes de habilitar el contrato.

### Features y estado

Cada funcionalidad agrupa presentación, aplicación y widgets cuando los
necesita. `AppController` coordina casos de uso y publica un `AppState`
inmutable. Los widgets solo leen o invocan ese controlador.

## Flujo principal

1. El arranque carga clientes, líneas, catálogo, historial y preferencias.
2. El usuario selecciona o crea un cliente.
3. Agrega productos; el dominio resuelve comodato y combina duplicados.
4. La ejecución valida y consume el stream de `AutomationGateway`.
5. El gateway demo se detiene en `waitingForReview`.
6. La confirmación completa la ejecución y guarda un snapshot en historial.
7. El historial puede agregar o reemplazar productos conservando datos.

## Responsive y accesibilidad

Los teléfonos usan `NavigationBar`; anchos mayores usan `NavigationRail`.
Formularios emplean `Wrap`, tarjetas, listas desplazables y hojas inferiores.
Los controles Material mantienen áreas táctiles y semántica. Las pruebas cubren
390×844 y 1100×800 sin overflow.

## Errores y seguridad

Los errores de validación se muestran antes de ejecutar. Dio transforma fallos
de transporte en `NetworkException`. No se registran secretos y el
almacenamiento seguro está reservado para tokens futuros.

## Persistencia del MVP

SharedPreferences guarda modo demo, URL y tema. Clientes, productos, ejecución
e historial demo están en memoria y se reinician al cerrar la app. La
persistencia empresarial deberá residir en la API, no en archivos móviles.
