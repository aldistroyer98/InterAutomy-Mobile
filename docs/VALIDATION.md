# Validación IA Flutter3

Fecha de inicio: 12 de julio de 2026 (America/Lima).

## Línea base confirmada

- Proyecto móvil: `main`, `8b0fb34` (`IA Flutter2`), árbol limpio antes de
  editar.
- Referencia desktop analizada sin modificar: `e238e4788e40d96c7d3f2387dcc60d51123159b0` (`IA1`).
- Dependencias WebView resueltas localmente: `webview_flutter 4.14.1` y
  `webview_flutter_android 4.13.0`.

## Controles de esta iteración

| Control | Resultado |
| --- | --- |
| `dart format` | Ejecutado; el formateador no reportó cambios pendientes. |
| `dart pub get --offline` | Dependencias resueltas; el sandbox impide actualizar telemetría fuera del workspace. |
| `dart analyze` | Sin incidencias, ejecutado con el SDK Dart del entorno. |
| `flutter test` | Pendiente de ejecución final por bloqueo externo del wrapper Flutter. |
| APK / AAB | Pendientes de ejecución final por el mismo bloqueo del wrapper Flutter. |
| Portal Automy real | No ejecutado: no se proporcionó URL ni acceso autorizado. |

El bloqueo observado del wrapper `flutter --version` supera 60 segundos en esta
sesión. El binario Dart del SDK funciona, por lo que permitió formato, resolución
offline y análisis. No se inventan resultados de APK, AAB ni pruebas contra
Automy real.

## Evidencia pendiente manual

Seguir [WEBVIEW_TEST_PLAN.md](WEBVIEW_TEST_PLAN.md) con URL y cuenta de prueba
autorizadas antes de habilitar selectores de cliente adicionales, productos,
comodatos, importación o envío automático.
