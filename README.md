# InterAutomy Mobile

InterAutomy Mobile es una aplicación Flutter autónoma para Android. Mantiene el
modo demostración de IA Flutter2 y añade el primer incremento IA Flutter3: un
navegador Automy integrado basado en Android WebView, con inicio de sesión
manual, diagnóstico local y una prueba de automatización de NRO OC.

No utiliza PC, FastAPI, una API propia, Selenium, ChromeDriver, Python,
AccessibilityService ni automatización por coordenadas. El WebView es el motor
Android incorporado en la app; no controla Google Chrome externo.

## Estado de viabilidad

- Modo demostración: disponible por defecto.
- Modo WebView: URL HTTPS del portal y hosts SSO explícitos.
- Inicio de sesión: manual; las cookies las administra Android WebView.
- Diagnóstico: URL sin parámetros, host, título, carga, iframes y errores.
- Automatización preparada: detecta y verifica NRO OC con scripts locales.
- Envío final: manual. `allowAutomaticSubmission` es `false`.

No se declara automatización completa de cliente, productos o archivos: requiere
pruebas contra el portal autorizado y sus versiones de HTML.

## Uso

```powershell
flutter pub get
flutter run
```

1. En **Ajustes**, guarda la URL HTTPS de Automy.
2. Desactiva **Modo demostración**.
3. En **Ejecución**, abre Automy integrado.
4. Inicia sesión y navega manualmente al formulario.
5. Selecciona **Preparar pedido** para probar NRO OC.
6. Revisa y confirma el envío dentro de Automy.

## Arquitectura y seguridad

Las reglas de negocio permanecen en Dart. Los scripts JavaScript locales se
limitan al DOM del host autorizado y devuelven JSON tipado; no reciben ni
registran credenciales.

- [Arquitectura](docs/ARCHITECTURE.md)
- [Migración desde IA1](docs/WEBVIEW_MIGRATION.md)
- [Decisión técnica WebView](docs/WEBVIEW_TECHNICAL_DECISION.md)
- [Motor de automatización](docs/AUTOMATION_ENGINE.md)
- [Seguridad](docs/SECURITY.md)
- [Plan de pruebas](docs/WEBVIEW_TEST_PLAN.md)

## Validación y builds

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
flutter build appbundle --debug
```

Los resultados reales de la iteración se registran en
[docs/VALIDATION.md](docs/VALIDATION.md). No hay URL privada ni credenciales en
el repositorio o en CI.
