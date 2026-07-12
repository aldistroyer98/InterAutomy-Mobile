# Resultados reales IA Flutter5

- Fecha: 12 de julio de 2026 (America/Lima).
- Rama: `validation/automy-real-webview`.
- Commit base: `40b34f266d97f0f229c30ae5341175fcd5a31cb1`.
- Commit de validación: commit final `chore: finalize IA Flutter5 validation tooling` en esta rama.
- APK: `build/app/outputs/flutter-apk/app-debug.apk` (162 552 481 bytes).
- AAB: `build/app/outputs/bundle/debug/app-debug.aab` (78 744 022 bytes).
- Dispositivo: no disponible.
- Android: no probado.
- Android System WebView: no probado.
- URL sanitizada: no proporcionada.
- Portal Automy real: `NOT_TESTED`.

## Flujo probado

Se ejecutaron formato, análisis, pruebas Dart/widget y build base IA Flutter4. Los contratos IA Flutter5 utilizan únicamente fixtures ficticios. La prueba `integration_test/webview_fixture_validation_test.dart` está preparada para Android, pero no se ejecutó porque `flutter devices` no mostró Android y `flutter emulators` no encontró AVD; tampoco había system image instalada.

## Resultados reales

No se abrió Automy, no se realizó login, no se detectó una sesión real y no se escribió NRO OC real. No hubo envío.

## Fallos y bloqueos

- Bloqueo ambiental: no hay dispositivo Android ni AVD.
- Se intentó instalar `system-images;android-36;google_apis;x86_64`: el primer intento terminó con `Connection reset` al 17 %; el segundo agotó 20 minutos. No se generó `package.xml`, por lo que no se trató la descarga parcial como imagen válida.
- Bloqueo de autorización: no se proporcionaron URL, acceso, proceso de prueba ni NRO OC no productivo.

## Limitaciones

Fixtures y compilación prueban infraestructura, no compatibilidad con el DOM, SSO, certificados o WebView del portal real.

## Siguiente acción

Conectar un Android autorizado o instalar una imagen AVD, proporcionar acceso de prueba y completar la matriz sin enviar el formulario.

## Validación local final

| Control | Resultado |
|---|---|
| `flutter clean` | PASSED |
| `flutter pub get` | PASSED |
| `dart format .` | PASSED; 98 archivos, 0 cambios |
| `flutter analyze` | PASSED; sin incidencias |
| `flutter test` | PASSED; 60 pruebas |
| `flutter build apk --debug` | PASSED |
| `flutter build appbundle --debug` | PASSED |
| `flutter devices` | Sin Android; Windows/Chrome/Edge únicamente |
| `flutter emulators` | Ningún AVD disponible |
| `integration_test/webview_fixture_validation_test.dart` | NOT_TESTED; requiere Android |
| Automy real | NOT_TESTED; requiere autorización y Android |

El workflow incluye publicación del artefacto `interautomy-mobile-ia-flutter5-debug`, pero GitHub Actions remoto queda pendiente porque no se hizo push.
