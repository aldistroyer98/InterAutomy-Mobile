# Validación en Samsung Galaxy A26

## Dispositivo de referencia

| Propiedad | Valor observado en la línea base |
| --- | --- |
| Modelo | Samsung Galaxy A26 (`SM A266M`) |
| Android | Android 16, API 36 |
| ABI | `android-arm64` |
| Identificador | `R5CY341H3NN` |

La detección por ADB/Flutter está documentada en
[PARITY_BASELINE.md](PARITY_BASELINE.md). La presencia del dispositivo en esa
línea base no sustituye una prueba manual posterior al refactor: la última
ejecución de `adb devices` no encontró un dispositivo conectado.

## Procedimiento de repetición

```powershell
adb devices
flutter devices
flutter run -d R5CY341H3NN
```

Usar una instalación depurable del árbol que se va a entregar. No usar
automatización por coordenadas ni iniciar una sesión Automy real sin URL y
cuenta autorizadas.

## Registro de estado de esta fase

| Caso | Estado | Evidencia o condición para aprobar |
| --- | --- | --- |
| Dispositivo para ejecución final | BLOCKED | La línea base reconoció `SM A266M`, pero la última ejecución de `adb devices` no mostró un dispositivo conectado. |
| APK/AAB construibles | PASSED | APK y AAB debug se construyeron correctamente en el árbol actual tras corregir Kotlin. |
| Aplicación abre tras el refactor | NOT_TESTED | Ejecutar `flutter run` con el árbol actual. |
| Pantalla Cliente renderiza | NOT_TESTED | Seleccionar un cliente y crear un borrador. |
| Catálogo IA1 carga | NOT_TESTED | Elegir fuente IA1 y comprobar búsqueda/conteos visibles. |
| Selector de cliente | NOT_TESTED | Buscar/seleccionar sin bloqueo ni overflow. |
| Institución | NOT_TESTED | Probar seleccionar, crear y editar la institución desde Cliente, incluida persistencia tras reinicio. |
| Archivo OC | NOT_TESTED | Probar elegir, abrir, cambiar y quitar PDF, imagen y DOCX mediante SAF. |
| Productos IA1 | NOT_TESTED | Comprobar línea y relación producto, sin asumir precio/código. |
| Resolución de comodato | NOT_TESTED | Probar Auto, Sin comodato y específico con datos Demo. |
| Validación previa | NOT_TESTED | Confirmar errores tipados y acciones correctivas. |
| Ejecución Demo | NOT_TESTED | Recorrer ejecución, revisión y confirmación. |
| Ausencia de `CircularDependencyError` | NOT_TESTED | Verificar al iniciar Demo y al alternar WebView/Demo. |
| Revisión manual | NOT_TESTED | Confirmar que el estado no se contradice en la UI. |
| Historial | NOT_TESTED | Comprobar registro, detalle y restauración durante la misma sesión. |
| Restauración | NOT_TESTED | Probar agregar y reemplazar, incluida confirmación de impacto. |
| Perfiles locales | NOT_TESTED | Probar guardar, cargar, renombrar, duplicar y eliminar tras reiniciar la app. |
| Ajustes | NOT_TESTED | Cambiar fuente, modo y tema; volver a Demo. |
| WebView disponible | NOT_TESTED | Con URL vacía debe pedir configuración, no lanzar excepción. |
| Overflow, texto grande y landscape | NOT_TESTED | Probar 150 %, 200 % y rotación. |
| Segundo plano y reinicio | NOT_TESTED | Validar recuperación y límites de persistencia. |

El enunciado inicial reportaba validaciones manuales anteriores de navegación y
pantallas; se conservan como contexto, no como aprobación del binario posterior
al refactor. La validación Galaxy final está bloqueada hasta reconectar el
dispositivo. Automy real, login, carga de archivos en el portal y envío siguen
fuera de esta prueba hasta contar con autorización explícita.
