# InterAutomy-Mobile

InterAutomy-Mobile es una aplicación Flutter para Android que consolida el
flujo móvil de pedidos antes de ampliar la automatización real de Automy. La
aplicación no requiere PC, FastAPI, Selenium, ChromeDriver, un agente Windows
ni control de Chrome externo.

El WebView integrado se conserva para navegación HTTPS y asistencia manual en
el portal Automy. La automatización real de clientes, productos, archivos y
envío **no** forma parte de esta fase.

## Estado de esta fase

| Área | Estado verificable |
| --- | --- |
| Selección de motor | `SettingsController` selecciona Demo o WebView sin que el gateway dependa de `AppController`. |
| Flujo Demo | Cliente → productos → validación tipada → ejecución/revisión → confirmación → historial está implementado en el estado de la aplicación y cubierto por pruebas de regresión. |
| Fuente Demo | Disponible por defecto, con datos reproducibles para desarrollo y pruebas. |
| Fuente Catálogo IA1 | Disponible en Ajustes; consume assets JSON validados y no hace fallback silencioso a Demo. |
| Catálogo IA1 migrado | 3 128 clientes, 62 líneas y 8 838 relaciones línea-producto. Instituciones y comodatos: 0 porque no existían maestros versionados de IA1. |
| WebView | Conservado; URL, hosts permitidos, sesión, timeouts e inspector siguen configurables. La interacción real con Automy continúa manual y pendiente de una validación autorizada. |
| Persistencia compleja | `LocalDomainStore` versionado persiste clientes/instituciones locales, historial y perfiles en el directorio privado de la app; la integración de toda la UI sigue siendo parcial. |

El catálogo IA1 aporta únicamente los campos comprobables de los libros fuente:
nombres de cliente, líneas comerciales y relaciones línea-producto. No se
inventan precios, códigos comerciales, presentación, categoría, expiración,
instituciones ni comodatos. Por ello, los productos IA1 señalan explícitamente
los campos no verificados y la validación exige un precio autorizado antes de
ejecutar.

## Uso local

```powershell
flutter pub get
flutter run
```

1. En **Ajustes**, elige **Demo** o **Catálogo IA1** como fuente de datos.
2. Mantén **Demo** como motor para recorrer el flujo seguro sin Automy real.
3. Para WebView, selecciona ese motor y guarda una URL HTTPS junto con los hosts
   SSO que correspondan.
4. La validación previa muestra errores y advertencias tipados; los detalles
   técnicos solo se conservan en modo desarrollador.

## Límites deliberados

- No hay envío automático a Automy.
- No se automatizan productos, archivos ni formularios completos dentro del
  DOM de Automy.
- El archivo OC usa SAF y conserva solo URI, nombre y MIME; Cliente permite
  elegir, abrir, cambiar y quitar la referencia, sin cargarla a Automy.
- Clientes e instituciones personalizados se guardan en el almacén local.
  Cliente permite seleccionar, crear y editar instituciones; la gestión de
  comodatos todavía no está completa.
- Perfiles locales permite guardar, cargar, renombrar, duplicar y eliminar;
  todavía no muestra un indicador explícito de cambios sin guardar.
- Mercado/SEACE no se incluye en la navegación móvil de esta fase.

## Seguridad

- No se almacenan credenciales, cookies legibles, tokens ni secretos.
- JavaScript local solo se ejecuta en hosts HTTPS autorizados y se mantiene la
  política de navegación del WebView.
- Los mensajes para usuario no exponen excepciones técnicas. El detalle
  sanitizado está limitado al modo desarrollador.
- `tools/catalog_migration/` es una herramienta de desarrollo para convertir
  Excel a JSON; no se empaqueta dentro de Android ni forma parte del runtime.
- CI no publica los Excel de origen ni datos de autenticación.

## Verificación

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
flutter build appbundle --debug
python tools/catalog_migration/validate_catalog_assets.py
```

La línea base documentada pasó formato, análisis, 60 pruebas, APK y AAB antes
de esta consolidación. En el árbol actual, formato, `flutter analyze`, las 75
pruebas, APK debug, AAB debug y la validación de catálogos IA1 pasaron
localmente. La comprobación manual en Galaxy A26 y la ejecución remota de CI
siguen pendientes; consulta [VALIDATION.md](docs/VALIDATION.md).

## Documentación

- [Línea base de paridad](docs/PARITY_BASELINE.md)
- [Grafo de providers](docs/PROVIDER_DEPENDENCY_GRAPH.md)
- [Matriz de paridad Desktop–Mobile](docs/DESKTOP_MOBILE_PARITY_MATRIX.md)
- [Informe de migración del catálogo IA1](docs/CATALOG_MIGRATION_REPORT.md)
- [Modelo de dominio](docs/DOMAIN_MODEL.md)
- [Validación de pedidos](docs/ORDER_VALIDATION.md)
- [Reglas de comodatos](docs/COMODATO_RULES.md)
- [Formato y persistencia de perfiles](docs/PROFILE_FORMAT.md)
- [Validación en Galaxy A26](docs/GALAXY_A26_VALIDATION.md)
- [Alcance de Mercado](docs/MERCADO_MOBILE_SCOPE.md)
- [Evidencia de validación y CI](docs/VALIDATION.md)

Los documentos históricos de IA Flutter4/5 describen iteraciones anteriores;
esta documentación de paridad IA1 prevalece para el alcance actual cuando haya
diferencias.
