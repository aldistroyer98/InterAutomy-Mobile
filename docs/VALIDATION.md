# Evidencia de validación de la fase de paridad IA1

## Regla de lectura

Este documento no convierte una línea base histórica en evidencia del árbol
actual. Cada estado distingue entre resultados comprobados antes de la
consolidación y controles que deben ejecutarse nuevamente después de los cambios
de providers, catálogo y dominio.

## Línea base comprobada

| Dato | Resultado |
| --- | --- |
| Rama inicial | `validation/automy-real-webview` |
| Commit móvil de partida | `5f18a4799e4b99c1fa825fb6ea5c63ae855215b5` |
| Commit Desktop de referencia | `e238e4788e40d96c7d3f2387dcc60d51123159b0` (`IA1`) |
| Flutter / Dart | Flutter 3.44.6 / Dart 3.12.2 |
| Formato | PASSED: 98 archivos, 0 cambios. |
| Análisis | PASSED: sin incidencias. |
| Pruebas | PASSED: 60. |
| APK debug | PASSED. |
| AAB debug | PASSED. |
| Galaxy A26 detectado | PASSED: `R5CY341H3NN`, Android 16/API 36. |

La línea base y el bloqueo original se detallan en
[PARITY_BASELINE.md](PARITY_BASELINE.md). El error histórico era
`CircularDependencyError` al construir el gateway desde el controlador; el
grafo corregido se documenta en
[PROVIDER_DEPENDENCY_GRAPH.md](PROVIDER_DEPENDENCY_GRAPH.md).

## Controles requeridos para la entrega del árbol actual

```powershell
flutter clean
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
flutter build appbundle --debug
python tools/catalog_migration/validate_catalog_assets.py
git diff --check
git status --short
```

| Control | Estado de evidencia en este documento |
| --- | --- |
| Formato actual | PASSED: `dart format --output=none --set-exit-if-changed .` revisó 119 archivos sin cambios. |
| Validación estructural del catálogo IA1 | PASSED localmente el 12 de julio de 2026: 3 128 clientes, 62 líneas, 8 838 productos, 0 instituciones, 0 comodatos y checksum coincidente. CI la repite antes de las pruebas Flutter. |
| Análisis estático actual | PASSED: `flutter analyze` no informó incidencias. |
| Suite Flutter actual | PASSED: `flutter test --reporter compact` completó 75 pruebas sin fallos. |
| Pruebas de grafo, catálogo y validación | PASSED dentro de la suite completa, incluidas `provider_graph_test.dart`, `catalog_migration_test.dart` y `order_validation_service_test.dart`. |
| Persistencia, selector OC e institución/perfil | PASSED dentro de la suite completa mediante pruebas tipadas de almacén local, selector y controlador Cliente. |
| Integración en dispositivo | BLOCKED: el último `adb devices` no mostró Galaxy A26; ver `GALAXY_A26_VALIDATION.md`. |
| APK y AAB actuales | PASSED: ambos debug se construyeron correctamente tras corregir Kotlin. |
| GitHub Actions remoto | PENDING hasta push y ejecución visible. |

`PENDING` expresa falta de evidencia final en este documento, no un resultado
fallido. Solo se cambia a `PASSED` con el comando y el árbol exactos de la
entrega. Un fallo debe registrar comando, fecha, salida relevante y causa sin
incluir secretos.

## Alcance de CI

El workflow ejecuta instalación, formato, validación de assets, análisis,
pruebas, APK debug y AAB debug. Publica tres artefactos sin Excel fuente:

- `interautomy-mobile-parity-debug-apk`
- `interautomy-mobile-parity-debug-aab`
- `catalog-migration-report`

CI no abre Automy real, no contiene credenciales y no prueba una URL privada.
