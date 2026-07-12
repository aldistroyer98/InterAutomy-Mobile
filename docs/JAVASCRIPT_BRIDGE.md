# Puente Dart–JavaScript

Los archivos en `assets/automation/` se empaquetan con la APK y no se descargan.
`JavascriptRunner` comprueba el origen autorizado antes de ejecutarlos y
serializa el payload con `jsonEncode`; no interpola texto de usuario como código.

Los scripts devuelven JSON: `success`, `code`, `message`, `retryable` y `data`.
`common.js` implementa búsqueda de selector, visibilidad, setter nativo y los
eventos `input`, `change` y `blur`, útiles para inputs controlados por React.
No existe un canal nativo genérico expuesto a la web; los resultados vuelven por
`runJavaScriptReturningResult` y se validan en Dart.
