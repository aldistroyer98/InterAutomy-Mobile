# InterAutomy-Mobile

InterAutomy-Mobile es una aplicación Flutter autónoma para Android. Su flujo real es:

`InterAutomy-Mobile → Android WebView integrado → portal Automy`

No requiere PC, FastAPI, Selenium ni ChromeDriver. El WebView es el componente web incorporado en la aplicación Android; no controla Chrome externo. La URL privada del portal no forma parte del repositorio: el usuario la guarda localmente junto con los hosts SSO que autorice.

## Estado IA Flutter4

IA Flutter4 es una fase de diagnóstico técnico real y seguro, no una automatización completa de Automy.

- El modo Demo de IA Flutter2/3 continúa disponible.
- El modo Automy WebView permite abrir un portal HTTPS configurado localmente.
- El inicio de sesión y la navegación hasta el formulario son manuales.
- El Inspector Web resume página, framework, controles, iframes, Shadow DOM abierto, almacenamiento, popups y errores sin extraer HTML, cookies ni valores.
- La única automatización DOM habilitada es detectar, completar y volver a leer **NRO OC**, iniciada manualmente en modo desarrollador.
- El envío final siempre es manual dentro de Automy; la app no presenta un botón de envío automático.
- Productos, comodatos y carga automática de archivos en el portal están pendientes.

La infraestructura puede validarse con fixtures locales y CI. Login, persistencia de sesión y NRO OC contra Automy real solo se consideran confirmados después de la checklist Android con una URL y cuenta autorizadas.

## Uso

```powershell
flutter pub get
flutter run
```

1. En **Configuración**, mantén **Demo** o elige **Automy WebView**.
2. Para WebView, guarda la URL HTTPS y, si aplica, hosts SSO adicionales.
3. Activa **Modo desarrollador** para acceder a **Inspector Web**.
4. Abre el portal, inicia sesión y navega manualmente.
5. En Inspector Web ejecuta el diagnóstico o la prueba explícita de NRO OC.
6. Revisa y envía manualmente dentro de Automy.

Si falta la URL, Automy WebView permanece deshabilitado y la app muestra instrucciones.

## Seguridad

- JavaScript local solo se ejecuta en hosts HTTPS autorizados.
- No se almacenan credenciales ni se registran cookies, tokens, HTML o texto completo del portal.
- Nuevas ventanas y enlaces externos pasan por la política de navegación.
- Errores SSL no se ignoran.
- No se descargan scripts desde internet.
- No se usa Python, Appium, AccessibilityService, OCR ni automatización por coordenadas.

## Documentación

- [Alcance IA Flutter4](docs/IA_FLUTTER4_SCOPE.md)
- [Arquitectura](docs/ARCHITECTURE.md)
- [Decisión técnica WebView](docs/WEBVIEW_TECHNICAL_DECISION.md)
- [Motor de automatización](docs/AUTOMATION_ENGINE.md)
- [Seguridad](docs/SECURITY.md)
- [Plan de pruebas WebView](docs/WEBVIEW_TEST_PLAN.md)

Los documentos heredados sobre agente Windows o API describen alternativas obsoletas y no forman parte de la arquitectura operativa IA Flutter4.

## Validación

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
flutter build appbundle --debug
```

CI nunca abre Automy real y el repositorio no contiene URL privada, secretos ni credenciales.
