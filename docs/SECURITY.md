# Seguridad de WebView

- Solo HTTPS; `android:usesCleartextTraffic="false"`.
- Lista blanca centralizada: host del portal y hosts adicionales explícitos.
- Navegación y JavaScript se bloquean fuera de la lista.
- No se ignoran errores SSL; no hay `onReceivedSslError` personalizado.
- No se exponen canales JavaScript nativos genéricos.
- Datos al DOM mediante JSON; scripts locales y versionados en la APK.
- Bitácora saneada: contraseñas, tokens, cookies y Bearer se ocultan.
- No se registran HTML, valores de formularios, cookies o credenciales.
- `file://` está deshabilitado; archivos usan `content://` de SAF.
- La limpieza de sesión borra cookies, caché y almacenamiento web de forma
  explícita. La app deshabilita backup de datos Android.

El usuario debe autorizar conscientemente el host del portal en Ajustes. No se
admiten comodines, HTTP, usuarios/contraseñas dentro de URL ni redirecciones a
hosts desconocidos.
