# Migración de IA1 desktop a Android WebView

Referencia analizada: `e238e4788e40d96c7d3f2387dcc60d51123159b0` (`IA1`).
Se estudiaron `automation/workflow.py`, `browser_actions.py`,
`services/automy_runner.py`, y sus contratos de resultado y sesión. No se copió
código Python ni Selenium.

| Acción desktop | Implementación Selenium IA1 | Equivalente móvil WebView |
| --- | --- | --- |
| Abrir Automy | ChromeDriver crea Chrome | `WebViewController.loadRequest` HTTPS |
| Login | credenciales/manual en Chrome | Login manual dentro de WebView |
| Esperar elemento | `WebDriverWait` | `WaitManager` con polling y cancelación |
| Localizar campo | XPath/CSS disperso | `SelectorRegistry` con CSS alternativo |
| Escribir campo | `send_keys` y eventos | setter nativo + `input/change/blur` |
| Adjuntar archivo | `input.send_keys(ruta)` | selector Android con SAF |
| Revisión manual | espera cierre de Chrome | WebView abierto y detector de resultado |
| Confirmar éxito | URL/texto/pestaña | URL, DOM y señales de formulario |

El flujo IA1 abre Procesos, crea Pedido, importa productos, completa
condiciones y pausa con AutoValidación apagada. IA Flutter3 implementa la
viabilidad A–C: navegador, diagnóstico, detector de página y NRO OC. La
navegación compleja, productos y adjuntos automatizados requieren evidencias
contra el portal real antes de declararse migrados.

Riesgos: cambios de Ant Design, SSO en hosts no configurados, iframes
cross-origin, ventanas emergentes, restricciones de Android WebView y
selectores de archivos. Cada cambio HTML requiere actualizar selectores,
pruebas HTML locales y una prueba manual controlada.
