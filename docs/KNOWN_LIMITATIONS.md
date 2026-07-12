# Limitaciones conocidas

- No se recibió URL ni acceso a un entorno Automy real; no hubo prueba real de
  login, NRO OC, producto, archivo o envío.
- La automatización demostrable es la arquitectura y el script versionado de
  NRO OC; requiere que la página coincida con el fingerprint/selector.
- Productos, comodatos aplicados al DOM, importación Excel y carga OC no se
  declaran terminados.
- Ventanas `window.open` complejas y popup SSO no son gestionados completamente
  por el plugin oficial actual; se detectan enlaces potenciales en diagnóstico.
- No se automatiza el envío final ni se guarda una contraseña.
- Después de segundo plano o recreación de actividad debe revalidarse portal;
  no se reanuda un envío sensible automáticamente.
