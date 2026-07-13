# Auditoría de la serie de paridad IA1

Base auditada: `5f18a4799e4b99c1fa825fb6ea5c63ae855215b5`
Extremo auditado: `3d44632f074170b6ade76e9308b37ae8406834ed`

La serie es lineal y contiene cinco commits. No se reescribe el historial
publicado; las observaciones se corrigen en commits posteriores.

## `73e07fc` — `docs: record parity baseline and provider graph`

- Propósito: registrar alcance de paridad y explicar el ciclo Riverpod.
- Archivos: `docs/PARITY_BASELINE.md` y `docs/PROVIDER_DEPENDENCY_GRAPH.md`;
  107 líneas nuevas.
- Impacto: solo documentación. Identifica correctamente la ruta histórica
  `AppController -> automationGatewayProvider -> appControllerProvider`.
- Riesgos: la matriz era una declaración de diseño, no evidencia de dispositivo
  ni CI.
- Pruebas: no agrega pruebas.
- Deuda: asociar la explicación a una prueba que construya el grafo productivo.
- Adecuación del mensaje: correcta.

## `97f83ed` — `build: add reproducible IA1 catalog artifacts`

- Propósito: migrar los Excel IA1 a assets versionados y reproducibles.
- Archivos: 12; cinco catálogos, manifiesto y seis utilidades Python; 57,563
  líneas nuevas, principalmente JSON.
- Impacto: incorpora 3,128 clientes, 62 líneas y 8,838 productos; instituciones
  y comodatos quedan explícitamente vacíos.
- Riesgos: los productos solo tienen `id`, `lineId` y `name`; no hay precio,
  código comercial separado, presentación ni categoría. El checksum original
  sí correspondía a los blobs LF, pero el validador era sensible al checkout
  CRLF de Windows; el cálculo fue canonizado sin cambiar los catálogos.
- Pruebas: validadores Python de forma, unicidad, relaciones y manifiesto.
- Deuda: faltaba medir completitud y separar “consultable” de “ejecutable”.
- Adecuación del mensaje: correcta; describe artefactos reproducibles, no
  paridad operacional.

## `1d914da` — `feat: implement IA1 local parity workflows`

- Propósito: integrar catálogos, persistencia, perfiles, historial, OC SAF,
  validación, comodatos, UI y separación de configuración/gateway.
- Archivos: 60; 4,071 inserciones y 346 eliminaciones.
- Impacto: es el commit funcional principal. Introduce
  `SettingsController`, `LocalDomainStore`, repositorios de assets/locales y
  pruebas de dominio/provider.
- Riesgos: alcance muy amplio para un único commit; el store borraba el archivo
  principal antes del rename, no tenía backup ni checksum; la prueba del grafo
  no montaba `ExecutionScreen`; códigos/presentación/categoría incompletos eran
  warnings aunque impedían una ejecución fiel.
- Pruebas: agrega pruebas de controladores, catálogos, archivos, persistencia,
  validación, providers y widgets, más una integración de catálogo.
- Deuda: robustez de corrupción, integración Android real, calidad de catálogo
  y fuentes maestras faltantes.
- Adecuación del mensaje: razonable pero demasiado general para la magnitud y
  mezcla de cambios.

## `dae974f` — `ci: document IA1 parity and validate catalog assets`

- Propósito: añadir validación de catálogos al workflow, publicar APK/AAB y
  documentar modelo, alcance, validación y migración.
- Archivos: 11; workflow, README y nueve documentos; 630 inserciones y 123
  eliminaciones.
- Impacto: CI localmente definido con format/analyze/test/build y artefactos.
- Riesgos: documentación previa podía leerse como validación concluida aunque
  no había run remoto comprobado ni Galaxy conectado.
- Pruebas: no agrega casos; integra el validador existente al workflow.
- Deuda: publicar también el informe de calidad y verificar un run remoto.
- Adecuación del mensaje: correcta, aunque el commit también reestructura
  ampliamente README y documentación.

## `3d44632` — `Flutter1`

- Propósito real: retirar comentarios TODO generados de CMake.
- Archivos: `linux/flutter/CMakeLists.txt` y
  `windows/flutter/CMakeLists.txt`.
- Impacto: elimina exactamente cuatro líneas de comentarios; no cambia lógica
  Flutter, Dart, Android ni paridad IA1.
- Riesgos: ninguno funcional; el mensaje impide entender el cambio.
- Pruebas: no agrega ni modifica pruebas.
- Deuda: ninguna técnica derivada; sí deuda de trazabilidad del mensaje.
- Adecuación del mensaje: incorrecta. `Flutter1` no describe el cambio.

No se reescribirá este commit porque ya está publicado. `dae974f` es el padre
funcional y `1d914da` concentra la implementación funcional principal.
