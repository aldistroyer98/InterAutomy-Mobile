# Grafo de dependencias de providers

## Estado inicial

`AppController` se crea mediante `appControllerProvider`. Durante una ejecución
lee `automationGatewayProvider`. A su vez, el provider del gateway leía
`appControllerProvider.select((state) => state.settings.demoMode)` antes de
elegir Demo o WebView.

```text
AppController ── ref.read ──> AutomationGateway
      ▲                              │
      └──── ref.watch(demoMode) ─────┘
```

El `watch` se ejecutaba antes del ternario, por lo que también ocurría en modo
Demo. Riverpod valida dependencias al usar tanto `watch` como `read`; cambiar
uno por el otro no elimina el ciclo.

Había además una dependencia diferida de capa: `WebViewAutomationGateway`
recibía callbacks que leían URL, hosts, persistencia y timeouts desde
`AppController`. No era el disparador inmediato del modo Demo, pero conservaba
el acoplamiento prohibido.

## Providers iniciales

| Provider | Dependencias directas iniciales |
|---|---|
| `settingsRepositoryProvider` | `LocalSettingsRepository` |
| `demoAutomationGatewayProvider` | Configuración estática Demo |
| `webViewAutomationGatewayProvider` | `AppController` diferido para ajustes |
| `automationGatewayProvider` | `AppController`, gateway Demo, gateway WebView |
| `appControllerProvider` | clientes, productos, historial, ajustes, ejecución y gateway |

## Solución aplicada

Se introduce `settingsControllerProvider` como fuente única de `AppSettings`.
Solo depende de `settingsRepositoryProvider` y persiste cambios. La selección
del gateway depende de dicho controlador, no de `AppController`; WebView lee la
misma configuración independiente.

```text
SettingsRepository
        │
        ▼
SettingsController
        │
        ├─────────────► AutomationGatewayProvider ─► Demo/WebView gateway
        │                         │
        ▼                         ▼
  AppController ───────────────────┘
```

El único sentido permitido es configuración → gateway → ejecución. Nunca se
permite `AutomationGateway → AppController`.

## Manejo de inicialización

Si no se puede preparar el gateway, el usuario recibe el código
`EXECUTION_GATEWAY_INIT` y un mensaje accionable sin exponer excepciones. En
modo desarrollador se conserva un detalle sanitizado del provider y stack para
diagnóstico local.
