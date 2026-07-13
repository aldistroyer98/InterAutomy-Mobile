# Resultados de paridad — Samsung Galaxy A26

Dispositivo objetivo: Samsung Galaxy A26 `SM-A266M`, Android 16/API 36,
serial `R5CY341H3NN`.

Fecha de intento: 2026-07-13 (America/Lima).
Evidencia: `adb devices -l` devolvió una lista vacía. No apareció `unauthorized`;
el dispositivo simplemente no estaba conectado. `flutter devices` no pudo
usarse como evidencia del Galaxy sin un serial ADB disponible.

Todos los casos manuales quedan `BLOCKED`; ninguno se marca `PASSED` por
inferencia de pruebas automatizadas.

| # | Caso | Estado | Evidencia/nota |
|---:|---|---|---|
| 1 | App abre | BLOCKED | Galaxy no conectado |
| 2 | No hay crash | BLOCKED | Galaxy no conectado |
| 3 | No hay `CircularDependencyError` | BLOCKED | Galaxy no conectado |
| 4 | Modo Demo seleccionado | BLOCKED | Galaxy no conectado |
| 5 | Catálogo Demo carga | BLOCKED | Galaxy no conectado |
| 6 | Catálogo IA1 carga | BLOCKED | Galaxy no conectado |
| 7 | Cliente se busca | BLOCKED | Galaxy no conectado |
| 8 | Cliente se selecciona | BLOCKED | Galaxy no conectado |
| 9 | Institución local funciona | BLOCKED | Galaxy no conectado |
| 10 | Selector OC SAF abre | BLOCKED | Galaxy no conectado |
| 11 | Archivo puede seleccionarse | BLOCKED | Galaxy no conectado |
| 12 | Archivo puede quitarse | BLOCKED | Galaxy no conectado |
| 13 | Productos se buscan | BLOCKED | Galaxy no conectado |
| 14 | Línea filtra | BLOCKED | Galaxy no conectado |
| 15 | Producto se añade | BLOCKED | Galaxy no conectado |
| 16 | Producto incompleto se identifica | BLOCKED | Galaxy no conectado |
| 17 | Cantidad cambia | BLOCKED | Galaxy no conectado |
| 18 | Comodato automático funciona | BLOCKED | Galaxy no conectado |
| 19 | Sin comodato funciona | BLOCKED | Galaxy no conectado |
| 20 | Comodato explícito funciona | BLOCKED | Galaxy no conectado |
| 21 | Validación previa muestra errores | BLOCKED | Galaxy no conectado |
| 22 | Pedido válido habilita ejecución | BLOCKED | Galaxy no conectado |
| 23 | Ejecución Demo inicia | BLOCKED | Galaxy no conectado |
| 24 | Alcanza revisión | BLOCKED | Galaxy no conectado |
| 25 | Confirmación completa | BLOCKED | Galaxy no conectado |
| 26 | Historial se crea | BLOCKED | Galaxy no conectado |
| 27 | Historial abre detalle | BLOCKED | Galaxy no conectado |
| 28 | Restaurar agregar funciona | BLOCKED | Galaxy no conectado |
| 29 | Restaurar reemplazar funciona | BLOCKED | Galaxy no conectado |
| 30 | Perfil se guarda | BLOCKED | Galaxy no conectado |
| 31 | Perfil se carga | BLOCKED | Galaxy no conectado |
| 32 | App se cierra | BLOCKED | Galaxy no conectado |
| 33 | App se abre nuevamente | BLOCKED | Galaxy no conectado |
| 34 | Historial persiste | BLOCKED | Galaxy no conectado |
| 35 | Perfiles persisten | BLOCKED | Galaxy no conectado |
| 36 | Configuración persiste | BLOCKED | Galaxy no conectado |
| 37 | WebView sigue accesible | BLOCKED | Galaxy no conectado |
| 38 | Inspector sigue accesible | BLOCKED | Galaxy no conectado |
| 39 | Rotación no provoca overflow | BLOCKED | Galaxy no conectado |
| 40 | Segundo plano y retorno funcionan | BLOCKED | Galaxy no conectado |

## Reanudación

Conectar y desbloquear el teléfono, habilitar depuración USB y aceptar la huella
RSA. Repetir `adb devices -l` hasta obtener
`R5CY341H3NN device`, luego ejecutar la integración local y la matriz manual.
Una prueba automatizada en otro host o un APK compilado no sustituye esta
evidencia.
