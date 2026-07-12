# Decisión técnica WebView

Se seleccionó `webview_flutter 4.14.1` junto con
`webview_flutter_android 4.13.0`, plugins oficiales Flutter disponibles en el
entorno.

Cubren JavaScript local, `NavigationDelegate`, errores HTTP/web, URL/carga,
cookies mediante `WebViewCookieManager`, limpieza de storage y
`setOnShowFileSelector` Android. El código prohíbe `file://`, desactiva
geolocalización y entrega URIs de SAF al selector del portal.

No se incorpora `flutter_inappwebview`: no se demostró que Automy necesite
WebView headless, interceptación de red avanzada o ventanas múltiples reales.
El diagnóstico cuenta enlaces `target=_blank`; el plugin oficial no ofrece un
control completo de `onCreateWindow`. Si el portal depende de popup SSO real,
debe evaluarse con una prueba documentada antes de cambiar plugin.
