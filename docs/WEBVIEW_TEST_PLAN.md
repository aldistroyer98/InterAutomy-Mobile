# Plan de pruebas WebView

## Unitarias disponibles

- política HTTPS y host bloqueado;
- transiciones válidas e inválidas;
- backoff de reintentos;
- selector registry;
- resultado JSON JavaScript;
- saneamiento de bitácora.

## HTML local pendiente de implementar antes de CI DOM

Crear fixtures sin datos reales para login, input React-like, select,
productos dinámicos, loading, éxito, error y mutación DOM. Ejecutar scripts
contra WebView Android instrumentado, no contra Automy real en CI.

## Checklist manual real

1. Configurar hosts y abrir portal.
2. Login y restauración de sesión.
3. Navegación, volver y recargar.
4. Diagnóstico, iframe, error y enlace bloqueado.
5. NRO OC: completar y verificar.
6. Varios campos, filas de producto, comodato y archivo OC.
7. Revisión manual y señal verificable de éxito.
8. Internet caído, rotación, segundo plano y sesión expirada.

Registrar versión del selector y fingerprint antes de habilitar etapas D–G.
