# Integración de API

## Estado actual

Dio está configurado con URL editable, timeouts, cabecera de cliente y errores
tipados. Existen DTOs iniciales, pero los repositorios remotos están
desactivados: aún no existe un contrato funcional ni un servidor que pueda
validarse. El modo demo permanece activo por defecto.

## Endpoints previstos

| Método | Ruta | Uso |
| --- | --- | --- |
| POST | `/auth/login` | Obtener tokens de acceso y renovación |
| GET | `/clients` | Listar clientes autorizados |
| POST | `/clients` | Crear o actualizar perfil según contrato |
| GET | `/products` | Consultar catálogo y filtros |
| POST | `/executions` | Crear ejecución idempotente |
| GET | `/executions/{id}` | Consultar estado y bitácora |
| GET | `/history` | Buscar historial |
| GET | `/history/{id}` | Recuperar snapshot completo |

## Contrato recomendado

- JSON con nombres estables y versión de esquema.
- Fechas ISO 8601 en UTC.
- Dinero como decimal serializado o unidades menores; nunca `float` del
  servidor como fuente contable.
- Identificadores UUID generados en servidor, con clave de idempotencia aportada
  por el móvil.
- Estados equivalentes al enum móvil y progreso entre 0 y 1.
- Errores con `code`, `message`, `field_errors`, `trace_id` y estado HTTP.
- Snapshot de producto con precio, cantidad, línea, comodato y expiración.

## Autenticación

Usar OAuth2/OIDC o tokens de acceso breves emitidos por FastAPI y renovación
controlada. Guardar tokens solamente con `flutter_secure_storage`. Nunca
guardar contraseñas. Aplicar TLS y certificate pinning solo con un proceso
formal de rotación.

## Ejecuciones distribuidas

`POST /executions` debe ser idempotente. El agente Windows reclama trabajos con
lease, heartbeat y reintentos acotados. El móvil consulta por polling con
backoff o canal de eventos autenticado. La confirmación humana debe ser una
operación auditada y rechazar transiciones inválidas.

## Pasos FastAPI

1. Definir OpenAPI y ejemplos de éxito/error.
2. Modelar usuarios, roles, clientes, catálogo, ejecuciones, logs e historial.
3. Implementar autenticación, scopes y auditoría.
4. Añadir idempotencia, cola y máquina de estados transaccional.
5. Publicar entorno de staging con TLS.
6. Generar pruebas de contrato móvil-servidor.
7. Habilitar repositorios remotos mediante configuración solo después de pasar
   pruebas de compatibilidad y resiliencia.
