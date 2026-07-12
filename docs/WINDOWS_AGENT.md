# Agente Windows

## Responsabilidad

El agente es el único componente autorizado para ejecutar Selenium,
ChromeDriver, Excel o integraciones ligadas a Windows. La aplicación móvil no
incluye esas capacidades; crea y supervisa ejecuciones mediante la API.

## Topología propuesta

```text
Flutter móvil → API FastAPI → cola/estado → agente Windows → Automy web
                         ↘ auditoría e historial ↗
```

## Ciclo de trabajo

1. El agente se autentica con identidad de máquina, no con credenciales de
   usuario embebidas.
2. Reclama una ejecución pendiente mediante lease exclusivo.
3. Reporta `startingAgent`, `startingBrowser` y `fillingInformation` con logs.
4. En modo manual publica `waitingForReview` y mantiene heartbeat.
5. Recibe confirmación auditada o detecta el cierre controlado de Chrome.
6. Publica `completed`, `failed` o `cancelled` y libera recursos.

## Confiabilidad

- Idempotencia por execution ID.
- Un solo propietario por lease, con vencimiento y recuperación.
- Heartbeats, timeouts y cancelación cooperativa.
- Reintentos únicamente en pasos seguros.
- Capturas y logs con retención limitada y sin datos sensibles innecesarios.
- Resultado explícito por paso; ausencia de excepción no equivale a éxito.

## Seguridad

- mTLS o credenciales de máquina rotables almacenadas en el almacén seguro del
  sistema operativo.
- Lista de agentes autorizados, scopes mínimos y revocación.
- Perfil de Chrome aislado por entorno y permisos mínimos del servicio.
- Validación estricta de archivos y rutas; prohibir comandos arbitrarios.
- Cifrado en tránsito, auditoría correlacionada y red privada cuando sea viable.

## Próximos pasos

1. Extraer del desktop IA1 un adaptador de automatización sin UI Qt.
2. Definir protocolo de leasing, heartbeat, logs y confirmación.
3. Construir un worker de staging con navegador visible para revisión.
4. Probar cancelación, caída del agente, doble entrega y recuperación.
5. Empaquetar como servicio administrado y documentar actualización/rollback.
