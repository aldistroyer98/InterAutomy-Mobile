# Alcance IA Flutter4

## Objetivo

Validar de forma técnica, observable y segura el portal Automy dentro de Android WebView. La fase prepara diagnóstico reproducible y una única prueba DOM: localizar, completar y verificar NRO OC por acción manual del usuario.

## Alcance

- Configuración local de URL HTTPS y hosts autorizados.
- Login y navegación manual dentro del WebView.
- Detección sanitizada de página, framework, estructura, iframes, Shadow DOM abierto, almacenamiento, inputs de archivo, popups y errores.
- Fingerprint no sensible y versionado.
- Registro centralizado y versionado de alternativas para NRO OC.
- Prueba manual de detección, escritura mediante setter nativo, eventos `input/change/blur`, relectura y comparación exacta.
- Bitácora sanitizada y exportación JSON sin cookies, tokens, valores, HTML ni datos personales.
- Fixtures locales, pruebas Dart/widget y compilación Android en CI.

## Exclusiones

No se automatizan cliente completo, productos, comodatos, archivos ni envío. Tampoco se incorporan FastAPI, servidor, agente Windows, Selenium, ChromeDriver, Python en Android, Appium, AccessibilityService, coordenadas, Chrome externo, OCR, IA generativa o sincronización cloud.

## Criterios de aceptación

1. El modo Demo no pierde funcionalidad.
2. Sin URL, WebView queda deshabilitado con una advertencia útil.
3. JavaScript solo se ejecuta en el origen HTTPS autorizado.
4. Inspector Web muestra resúmenes y versiones sin contenido sensible.
5. PageDetector respeta prioridad de seguridad, sesión, error, éxito y revisión.
6. Un fingerprint no reconocido bloquea la escritura, pero permite diagnóstico manual.
7. La prueba NRO OC solo tiene éxito cuando el valor leído coincide exactamente con el esperado y persiste después de `blur`.
8. Iframe cross-origin, estructura incompatible, sesión expirada o cancelación detienen la prueba.
9. No existe acción de envío automático.
10. Formato, análisis, pruebas, APK y AAB debug pasan localmente; CI ejecuta la misma calidad salvo AAB.

## Riesgos

- Automy puede cambiar selectores, framework, navegación SSO o controles administrados.
- Un NRO OC puede estar en iframe cross-origin o Shadow Root cerrado, fuera del alcance seguro del WebView.
- Políticas corporativas, certificados o autenticación pueden impedir el uso embebido.
- Los fixtures prueban la infraestructura, no sustituyen una validación autorizada contra el portal real.

## Resultado esperado

Una aplicación preparada para inspeccionar el portal y ejecutar una prueba trazable de NRO OC. Hasta completar la checklist Android con acceso autorizado, el resultado real se declara **pendiente**, nunca confirmado por inferencia.
