# Arquitectura IA Flutter3

La app conserva Clean Architecture y Riverpod. La UI invoca `AutomationGateway`;
no crea ni controla un WebView directamente fuera de la pantalla de portal.

```text
UI / Riverpod
  ├─ DemoAutomationGateway (modo demostración)
  └─ WebViewAutomationGateway (modo portal)
       ├─ AutomyWebController + Navigation/Session services
       ├─ WebViewSecurityPolicy
       ├─ AutomationStateMachine + WaitManager + RetryPolicy
       ├─ PageDetector + SelectorRegistry
       ├─ JavascriptRunner + assets/automation/*.js
       └─ FilePickerService → Android Storage Access Framework
```

`AppSettings` persiste modo, URL del portal, hosts adicionales y tema con
SharedPreferences. Clientes, productos, comodatos e historial demo conservan
los contratos de IA Flutter2. No se persisten contraseñas, HTML, tokens ni
cookies legibles.

El gateway WebView crea un `AutomationContext` para el pedido, publica
`Execution`, permite cancelación y conserva la sesión. Al retornar de segundo
plano se debe volver a diagnosticar el DOM: no se reanuda un envío sensible de
forma automática.
