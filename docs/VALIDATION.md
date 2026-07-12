# Validación del MVP móvil

Fecha: 12 de julio de 2026 (America/Lima).

## Entorno

- Flutter 3.44.6 estable.
- Dart 3.12.2.
- Android SDK 36.1; plataforma 35 instalada por Gradle para el proyecto.
- Android application ID: `com.sistemasanaliticos.interautomy_mobile`.
- Baseline móvil: `139cf01` (`IA Flutter1`).
- Referencia desktop: `e238e4788e40d96c7d3f2387dcc60d51123159b0` (`IA1`).

## Controles ejecutados

| Control | Resultado |
| --- | --- |
| `dart format .` | 57 archivos, 0 cambios pendientes |
| `flutter pub get` | Correcto |
| `flutter analyze` | Sin incidencias |
| `flutter test` | 21 pruebas aprobadas |
| Widget compacto 390×844 | Aprobado, sin overflow |
| Widget expandido 1100×800 | Aprobado, sin overflow |
| `flutter build apk --debug` | Correcto |
| `flutter build appbundle --debug` | Correcto |
| Marcadores TODO/FIXME/plantilla | Ninguno |
| Patrones de secretos | Ninguno |
| Archivos desktop copiados | Ninguno |
| Carpeta de proyecto anidada | Ninguna |

El escenario completo cliente → producto → ejecución → revisión → confirmación
→ historial se ejecuta en la suite widget con gateway instantáneo. También
existe `integration_test/app_flow_test.dart`; su ejecución instrumentada queda
condicionada a un dispositivo Android externo, porque esta estación no dispone
de dispositivo ni AVD y Flutter no admite integration tests en Chrome.

## Artefactos

Los artefactos viven en `build/` y no se incluyen en Git.

| Artefacto | Tamaño | SHA-256 |
| --- | ---: | --- |
| `build/app/outputs/flutter-apk/app-debug.apk` | 161,541,229 bytes | `ED27EB23B1814BCBAECF5BA68CA73101F76FB09CA3389D33A315D1CE8DA51566` |
| `build/app/outputs/bundle/debug/app-debug.aab` | 77,877,193 bytes | `FA2972C832F9A596FB79ED4B9200B04BBD5357FDE29B091A071B30943C6E13F4` |

## Observaciones del entorno

- `flutter doctor` solo reporta Visual Studio ausente; no afecta Android.
- Windows tiene Developer Mode desactivado. Tras `flutter clean`, se usaron
  junctions efímeros dentro de `windows/flutter/ephemeral` para que Flutter
  recreara plugins sin cambiar ajustes del sistema. Esos archivos están
  ignorados por Git.
- `package_info_plus` se actualizó a 10.2.0, compatible con Flutter 3.44 y
  soporte de Kotlin integrado; la compilación final no presenta la advertencia
  de Kotlin que emitía la versión 9.x.
