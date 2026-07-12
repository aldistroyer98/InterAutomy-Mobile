# Motor de automatización

`WebViewAutomationGateway` implementa el contrato existente
`AutomationGateway`, por lo que `DemoAutomationGateway` sigue operativo. Recibe
el pedido, crea `AutomationContext`, publica `Execution`, admite cancelación y
mantiene bitácora saneada.

La máquina valida cada transición: `idle`, `openingPortal`, `waitingForPage`,
`detectingSession`, `waitingForLogin`, `navigating`, `fillingClient`,
`fillingConditions`, `fillingProducts`, `uploadingFiles`, `validating`,
`waitingForManualReview`, `submitting`, `detectingResult`, `completed`,
`cancelling`, `cancelled` y `failed`.

El incremento usa: abrir portal, esperar página, detectar sesión, esperar login
manual, exigir formulario conocido, escribir/verificar NRO OC y esperar revisión
manual. No pulsa el botón final aunque AutoValidación esté ON; la bandera de
seguridad lo impide.
