# Alcance IA Flutter5

## Objetivo único

Preparar y ejecutar una validación controlada en Android del portal Automy dentro del WebView, limitada a login manual, sesión, diagnóstico y detección/escritura/verificación de NRO OC. No es una ampliación de automatización funcional.

## Estados de evidencia

- **Probado con fixtures:** comportamiento reproducible usando HTML ficticio local.
- **Preparado para Automy:** código compilado y controles disponibles, aún sin portal real.
- **Probado en Automy real:** solo después de una ejecución autorizada en Android con evidencia sanitizada.
- **Pendiente / NOT_TESTED:** no hubo dispositivo, acceso o condición necesaria.

Al iniciar esta iteración no se detectó dispositivo Android ni AVD, y no había una imagen de sistema instalada. Por tanto ninguna función del portal real puede marcarse como aprobada hasta completar la matriz manual.

## Alcance técnico

- URL HTTPS y hosts autorizados configurados localmente.
- Persistencia de sesión configurable sin leer ni almacenar cookies.
- Eventos sanitizados de navegación, redirección, decisión, SSL, DNS, timeout y cancelación.
- Modelo de validación de sesión sin credenciales ni cookies.
- Inspector real enriquecido con estado de sesión y prueba NRO OC.
- Descubrimiento versionado del selector NRO OC.
- Escritura manualmente iniciada, doble verificación de estabilidad y detección contextual de error.
- Cancelación cooperativa sin cerrar sesión ni ejecutar botones del portal.
- Fixtures/CI separados de la matriz Automy real.

## Exclusiones

Cliente completo, productos, comodatos, archivos, AutoValidación real, envío, clic final, FastAPI, servidor, agente Windows, Selenium, ChromeDriver, Python Android, Appium, AccessibilityService, Chrome externo, coordenadas, OCR, IA generativa y scripts remotos.

## Criterios de seguridad

- Nunca persistir usuario, contraseña, cookies, tokens, headers o valores completos del formulario.
- Nunca ignorar SSL ni autorizar hosts de forma automática.
- Nunca ejecutar JavaScript fuera de HTTPS y la lista blanca explícita.
- Nunca presentar fixtures, compilación o navegador desktop como validación Android real.
- No hacer push hasta finalizar las comprobaciones locales.

## Evidencia requerida para Automy real

URL y acceso autorizados, proceso no productivo, NRO OC ficticio y confirmación explícita de no enviar. La ejecución debe registrar únicamente host, path sanitizado, versiones, códigos, tiempos y resultados enmascarados.
