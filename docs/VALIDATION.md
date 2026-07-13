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
| Auditoría/pruebas Python | PASSED; 3 pruebas, 0.195 s; incluye igualdad LF/CRLF |
| `flutter analyze` | PASSED; sin issues, 2.1 s |
| `flutter test --reporter expanded --timeout 60s` | PASSED; 87 pruebas, 11 s reportados/26 s de pared |
| Provider graph productivo | PASSED; construye repositorio/configuración, ambos gateways, selector, `AppController` y `ExecutionScreen`; recorre Demo→WebView sin URL→Demo, dispose y rebuild |
| Persistencia | PASSED; esquema, checksum, backup, recuperación, concurrencia e interrupción |
| Flujo IA1 con fixture válido | PASSED en host; Demo llega a revisión, confirma, guarda historial/perfil y los restaura con un store nuevo |
| IA1 incompleto | PASSED; sigue consultable y la ejecución se bloquea por precio, código, presentación y categoría |
| `flutter build apk --debug` | PASSED; 73.3 s desde limpio y rebuild final 12.6 s |
| `flutter build appbundle --debug` | PASSED; 18.1 s desde limpio y rebuild final 11.7 s |
| Integración Android | BLOCKED; no hay dispositivo/AVD conectado |
| Integración Windows alternativa | BLOCKED por falta de toolchain Visual Studio; no es un fallo Android |

## Artefactos locales

| Artefacto | Bytes | SHA-256 |
|---|---:|---|
| `build/app/outputs/flutter-apk/app-debug.apk` | 161,683,794 | `E67335F82ABEF05B9B9888AF53AE0771A1772A9531B5227B9184C72B0C689B9F` |
| `build/app/outputs/bundle/debug/app-debug.aab` | 77,968,130 | `BC8952B17AA37481CFC3AF4E5C76D947DB800EC4224649CCCE656E007C92D864` |
| `build/reports/catalog_quality_report.json` | 3,564 | `216E1C3B521989444AFEC5B893868EACDF9880D1B2CA4C4791C86EBE4A26FE73` |
| `build/reports/catalog_quality_report.md` | 2,182 | `E3C7DE69B118AC745848076AEEFDF19671C5813A117EC61EDBE27637F1E62963` |

Los informes bajo `build/` son generados y no se versionan. CI los publica
dentro de `catalog-migration-report`.

## CI remoto comprobado

El primer push de las correcciones produjo el run `29250784292` (`Flutter CI
#8`) sobre `9fdd9b9b9c5c53cfd835f3f264ff55743f46872b` y falló en el checksum del
manifiesto. La causa fue que Python y Dart calculaban bytes CRLF en Windows y
LF en Linux. El cálculo se canonizó y se agregó una regresión multiplataforma;
no se modificó el contenido de los cinco catálogos.

GitHub Actions run `29251156199` (`Flutter CI #9`) corresponde al commit
`f75b408600466d09f80b3c3faed80127837b5104` en
`feature/ia1-mobile-parity`. El job `Formato, catálogos, pruebas y Android`
terminó `success`; sus 15 pasos de dependencias, formato, validación/auditoría,
pruebas Python, análisis, 87 pruebas Flutter, APK, AAB y uploads terminaron
`success`.

Artefactos remotos comprobados, creados el 2026-07-13 y con expiración
2026-07-20:

- `interautomy-mobile-parity-debug-apk` — ID `8279572192`, 83,270,045 bytes
  comprimidos, digest `cebb1888…17e2a`;
- `interautomy-mobile-parity-debug-aab` — ID `8279573623`, 77,164,013 bytes
  comprimidos, digest `5637b393…ef3bc`;
- `catalog-migration-report` — ID `8279573905`, 4,016 bytes comprimidos,
  digest `d83f790f…19015`.

Los tres artefactos declaran la rama `feature/ia1-mobile-parity`, SHA
`f75b408600466d09f80b3c3faed80127837b5104` y expiración 2026-07-20.

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
