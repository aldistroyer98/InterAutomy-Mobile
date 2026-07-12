# Checklist Android IA Flutter4

Usar únicamente una URL y cuenta de prueba autorizadas. No incluir credenciales, cookies, datos personales ni NRO OC completos en capturas o diagnósticos.

## Preparación

- [ ] Instalar el APK debug generado para IA Flutter4.
- [ ] Abrir InterAutomy-Mobile.
- [ ] Mantener Demo y confirmar Clientes, Productos, Ejecución, Historial, Configuración y tema.
- [ ] Configurar la URL HTTPS de Automy y los hosts SSO estrictamente necesarios.
- [ ] Validar que HTTP, `file:`, `data:`, `javascript:` y hosts no autorizados se bloquean.
- [ ] Elegir Automy WebView y activar Modo desarrollador / Modo diagnóstico.

## Portal y sesión

- [ ] Abrir el portal integrado.
- [ ] Iniciar sesión manualmente.
- [ ] Confirmar que enlaces externos solicitan aprobación y no reciben automatización.
- [ ] Cerrar y reabrir el portal.
- [ ] Comprobar si la sesión persiste; registrar el resultado real.
- [ ] Cerrar sesión y usar **Limpiar sesión** para borrar cookies, caché y storage.

## Diagnóstico

- [ ] Abrir Inspector Web desde Configuración.
- [ ] Abrir Inspector Web desde Portal.
- [ ] Ejecutar diagnóstico.
- [ ] Confirmar página detectada y fingerprint.
- [ ] Confirmar framework y señales.
- [ ] Confirmar resumen de formularios, inputs, selects, botones, tablas y file inputs.
- [ ] Confirmar iframes y clasificación same-origin / cross-origin.
- [ ] Confirmar Shadow DOM abierto y límites de inspección.
- [ ] Confirmar popup/`target=_blank`.
- [ ] Confirmar booleanos de sessionStorage, localStorage y cookies sin mostrar contenido.

## Prueba NRO OC

- [ ] Navegar manualmente al formulario correcto.
- [ ] Escribir un valor ficticio de prueba.
- [ ] Pulsar **Detectar campo**.
- [ ] Revisar clave lógica, alternativa, tiempo y reintentos.
- [ ] Pulsar **Completar NRO OC**.
- [ ] Confirmar que solo cambia NRO OC.
- [ ] Pulsar **Verificar valor**.
- [ ] Confirmar éxito solo si el valor leído coincide y persiste tras blur.
- [ ] Confirmar bloqueo ante fingerprint desconocido o iframe cross-origin.
- [ ] Pulsar **Limpiar prueba**.
- [ ] Confirmar que no existe botón de envío automático.

## Ciclo de vida y red

- [ ] Rotar a landscape y volver a portrait sin overflow.
- [ ] Probar teléfono, tableta, texto 150 % y texto 200 %.
- [ ] Enviar la app a segundo plano y volver.
- [ ] Desconectar internet y observar error sanitizado.
- [ ] Reconectar y recargar manualmente.

## Exportación

- [ ] Exportar `interautomy_diagnostic_YYYYMMDD_HHMMSS.json`.
- [ ] Confirmar versiones, resumen, fingerprint, selector y timestamps.
- [ ] Confirmar ausencia de cookies, contraseñas, tokens, valores, nombres, direcciones, teléfonos, correos, HTML, body completo y headers.

## Evidencia

Registrar dispositivo, versión Android/WebView, fecha, página y códigos obtenidos. Clasificar cada punto como aprobado, fallido o no ejecutado. No convertir “preparado” en “confirmado” sin esta prueba real.
