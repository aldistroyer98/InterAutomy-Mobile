# Línea base de paridad IA1

## Alcance comprobado

| Elemento | Resultado |
|---|---|
| Rama móvil | `validation/automy-real-webview` |
| Commit móvil | `5f18a4799e4b99c1fa825fb6ea5c63ae855215b5` — `chore: finalize IA Flutter5 validation tooling` |
| Referencia Desktop | `e238e4788e40d96c7d3f2387dcc60d51123159b0` — `IA1` |
| Estado Git inicial | Limpio; la rama y `origin/validation/automy-real-webview` apuntaban al mismo commit |
| Flutter / Dart | Flutter 3.44.6 / Dart 3.12.2 |
| Dispositivo visible | Samsung Galaxy A26, `SM A266M`, Android 16 / API 36, `R5CY341H3NN`, `android-arm64` |
| `dart format --output=none --set-exit-if-changed .` | Correcto: 98 archivos, 0 cambios |
| `flutter analyze` | Correcto: sin incidencias |
| `flutter test` | Correcto: 60 pruebas superadas |
| `flutter build apk --debug` | Correcto |
| `flutter build appbundle --debug` | Correcto |

## Entorno de ejecución

`flutter clean` y los comandos de validación se ejecutaron correctamente. En
esta sesión VS Code mantenía procesos `tooling-daemon`, servidor de lenguaje y
DevTools que retenían el bloqueo global del SDK Flutter/Dart. Se detuvieron
temporalmente únicamente para cada comando CLI; no se modificó la configuración
del IDE ni el proyecto por esa causa.

## Bloqueo funcional conocido

El escenario reportado en el Galaxy A26 mostraba:

```text
CircularDependencyError: Circular dependency detected.
Provider<AutomationGateway> depende de sí mismo.
```

La inspección de código confirma el ciclo estructural. La batería base no lo
detectó porque las pruebas de flujo reemplazan `automationGatewayProvider` y
no construyen simultáneamente el controlador y el gateway de producción. La
corrección y su prueba de regresión forman parte de esta fase.

## Límites de esta línea base

La presencia del Galaxy A26 fue comprobada por ADB/Flutter. La ejecución manual
de la app en este dispositivo se realizará después del refactor; ningún resultado
de UI Android se marca como aprobado todavía.
