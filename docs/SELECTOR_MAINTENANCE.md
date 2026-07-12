# Mantenimiento de selectores

Todos los selectores viven en `lib/automation/selectors/selector_registry.dart`.
Cada definición tiene clave lógica, alternativas CSS, descripción, página,
obligatoriedad y versión. Los scripts reciben esas alternativas desde Dart; no
contienen selectores Automy repetidos.

Cuando Automy cambie:

1. Capture el diagnóstico sin datos de formulario.
2. Actualice alternativas y aumente la versión de selector.
3. Ejecute pruebas unitarias y HTML local.
4. Pruebe manualmente el campo afectado en un pedido no productivo.
5. No añada selectores basados solo en posición o datos personales.
