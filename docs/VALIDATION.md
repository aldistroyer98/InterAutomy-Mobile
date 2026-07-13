# Evidencia de validación de paridad IA1

Fecha: 2026-07-13 (America/Lima).
Rama local: `feature/ia1-mobile-parity`.
Commit inicial: `3d44632f074170b6ade76e9308b37ae8406834ed`.
Referencia Desktop auditada: `e238e4788e40d96c7d3f2387dcc60d51123159b0`.

## Validación local desde cero

Los resultados siguientes se obtuvieron después de los cambios actuales; no se
copiaron de validaciones anteriores.

| Control | Resultado |
|---|---|
| `flutter clean` | PASSED; 6.8 s, eliminó `build`, `.dart_tool` y efímeros |
| `flutter pub get` | PASSED; 2.2 s |
| `dart format --output=none --set-exit-if-changed .` | PASSED; 123 archivos, 0 cambios |
| `python tools/catalog_migration/validate_catalog_assets.py` | PASSED; 3,128 clientes, 62 líneas, 8,838 productos, 0 instituciones, 0 comodatos; checksum canónico `7ba838e3…aad2` |
| Auditoría/pruebas Python | PASSED; 2 pruebas, 0.197 s |
| `flutter analyze` | PASSED; sin issues, 2.1 s |
| `flutter test --reporter expanded --timeout 60s` | PASSED; 87 pruebas, 11 s reportados/26 s de pared |
| Provider graph productivo | PASSED; construye repositorio/configuración, ambos gateways, selector, `AppController` y `ExecutionScreen`; recorre Demo→WebView sin URL→Demo, dispose y rebuild |
| Persistencia | PASSED; esquema, checksum, backup, recuperación, concurrencia e interrupción |
| Flujo IA1 con fixture válido | PASSED en host; Demo llega a revisión, confirma, guarda historial/perfil y los restaura con un store nuevo |
| IA1 incompleto | PASSED; sigue consultable y la ejecución se bloquea por precio, código, presentación y categoría |
| `flutter build apk --debug` | PASSED; Gradle 73.3 s |
| `flutter build appbundle --debug` | PASSED; Gradle 18.1 s |
| Integración Android | BLOCKED; no hay dispositivo/AVD conectado |
| Integración Windows alternativa | BLOCKED por falta de toolchain Visual Studio; no es un fallo Android |

## Artefactos locales

| Artefacto | Bytes | SHA-256 |
|---|---:|---|
| `build/app/outputs/flutter-apk/app-debug.apk` | 161,683,794 | `7EE49531AD95A80E5D5671B5528919D20A54902D412C2AF6E91081659D74F5FB` |
| `build/app/outputs/bundle/debug/app-debug.aab` | 77,969,106 | `F20611CF0EDC63F120B3A0E7E8EBC9B6DEA1CC17F12688449D3CAF9A038AE375` |
| `build/reports/catalog_quality_report.json` | 3,564 | `BDF3717402093B13F5D418D8B71DB79F9650F79CB5263A11B302BC5DEF99E126` |
| `build/reports/catalog_quality_report.md` | 2,182 | `891B1938C0219871A7980E0C6E84BF1BB2F9CCF2B7591B75F14EE82DB54CE9AE` |

Los informes bajo `build/` son generados y no se versionan. CI los publica
dentro de `catalog-migration-report`.

## CI remoto comprobado

GitHub Actions run `29245377814` (`Flutter CI #7`) corresponde al commit
`3d44632f074170b6ade76e9308b37ae8406834ed` en
`validation/automy-real-webview`. El job
`Formato, catálogos, pruebas y Android` terminó `success`; sus pasos de formato,
catálogo, análisis, pruebas, APK, AAB y uploads terminaron `success`.

Artefactos remotos comprobados, creados el 2026-07-13 y con expiración
2026-07-20:

- `interautomy-mobile-parity-debug-apk` — 83,261,929 bytes comprimidos;
- `interautomy-mobile-parity-debug-aab` — 77,157,590 bytes comprimidos;
- `catalog-migration-report` — 1,797 bytes comprimidos.

Este run valida el commit base publicado. El estado remoto de las correcciones
posteriores queda `PENDING` hasta hacer commit/push y observar un run nuevo; no
se extrapola el verde anterior.

## Galaxy A26

`adb devices -l` devolvió la lista vacía. El serial `R5CY341H3NN` no estuvo
disponible, por lo que `flutter run -d R5CY341H3NN`, la integración Android y la
matriz de 40 casos quedan `BLOCKED`. Ver
`GALAXY_A26_PARITY_RESULTS.md`. Ningún caso manual se marca aprobado por el
hecho de que compile o pase una prueba host.

## Alcance de CI

El workflow actual ejecuta dependencias, formato, validación y auditoría de
catálogos, pruebas Python, análisis, pruebas Flutter, APK y AAB. Publica:

- `interautomy-mobile-parity-debug-apk`;
- `interautomy-mobile-parity-debug-aab`;
- `catalog-migration-report` con migración y calidad JSON/Markdown.

CI no abre Automy, no contiene credenciales y no sustituye la prueba física del
Galaxy.
