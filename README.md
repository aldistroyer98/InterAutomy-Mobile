# InterAutomy Mobile

Aplicación Flutter empresarial para preparar pedidos de InterAutomy desde un
teléfono o tableta. El MVP trabaja en modo demostración: administra clientes y
productos, simula la ejecución, solicita revisión humana y conserva historial
restaurable. No ejecuta Selenium ni ChromeDriver.

## Tecnologías

- Flutter 3.44 y Dart 3.12 con null safety.
- Material 3 y navegación responsive con `go_router`.
- Estado centralizado con Riverpod.
- Preferencias con SharedPreferences y almacenamiento seguro reservado para
  futuros tokens.
- Cliente HTTP preparado con Dio; integración remota desactivada.
- Pruebas unitarias, widget e integración.

## Arquitectura

El dominio es Dart puro. La UI observa providers y no crea repositorios. La
capa `data` implementa contratos del dominio con repositorios demo o locales.
La automatización se abstrae detrás de `AutomationGateway`, para que una API y
un agente Windows sustituyan al simulador sin llevar Selenium al móvil.

```text
lib/
  app/       arranque, tema, configuración y rutas
  core/      errores, red, responsive y widgets compartidos
  domain/    entidades, contratos, servicios y validadores
  data/      datos demo, DTOs y repositorios
  features/  clientes, productos, ejecución, historial y ajustes
  state/     providers, estado y controlador central
```

Más detalle en [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Instalación

Requisitos: Flutter estable compatible, Android SDK y licencias aceptadas.

```powershell
git clone https://github.com/aldistroyer98/InterAutomy-Mobile.git
cd InterAutomy-Mobile
flutter pub get
```

No es necesario configurar secretos para el modo demo.

## Ejecución

```powershell
flutter run
```

La aplicación usa `com.sistemasanaliticos.interautomy_mobile` como
`applicationId` Android y muestra el nombre **InterAutomy**.

## Pruebas y análisis

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter test integration_test/app_flow_test.dart -d <android-device-id>
```

La prueba de integración requiere un dispositivo o emulador Android conectado.

## Builds Android

```powershell
flutter build apk --debug
flutter build appbundle --debug
```

Para producción debe configurarse firma release, versión, íconos definitivos,
políticas y ficha de tienda. Véase [docs/PLAY_STORE.md](docs/PLAY_STORE.md).

## Modo demostración

Está activo por defecto e incluye San Borja, Miraflores y Surco; líneas ABBOTT,
ROCHE y BIOMERIEUX; catálogo demo; comodatos; simulación progresiva; revisión
manual e historial en memoria. Las preferencias de tema, modo y URL sí se
guardan localmente.

## Referencia desktop IA1

La adaptación conceptual se basó en el commit desktop
`e238e4788e40d96c7d3f2387dcc60d51123159b0` (`IA1`). No se copiaron
dependencias Qt, Selenium, Excel ni código ligado a Windows. El análisis está
en [docs/DESKTOP_REFERENCE.md](docs/DESKTOP_REFERENCE.md).

## API futura y agente Windows

La app documenta los endpoints esperados y contiene Dio, DTOs, errores y URL
configurable, pero los repositorios remotos están deliberadamente desactivados
hasta publicar y validar el contrato. La automatización real será responsabilidad
de un agente Windows autorizado.

- [docs/API_INTEGRATION.md](docs/API_INTEGRATION.md)
- [docs/WINDOWS_AGENT.md](docs/WINDOWS_AGENT.md)

## Seguridad

- No hay contraseñas, tokens ni claves reales en el repositorio.
- La app móvil nunca lanza procesos locales, ChromeDriver ni Selenium.
- Los futuros tokens deben almacenarse con `flutter_secure_storage`.
- La API deberá aplicar TLS, autenticación, autorización, idempotencia, auditoría
  y expiración de credenciales.

## Git

La rama principal es `main`. Antes de integrar cambios se exige formato,
análisis y pruebas. CI reproduce esas validaciones sin secretos. Las pautas de
desarrollo están en [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).
