# Reglas de comodatos

## Prioridad IA1 implementada

`ComodatoResolutionService` resuelve el comodato de un producto sin que un
widget decida la regla. El resultado incluye un origen explícito:
`explicit`, `line`, `general`, `none` o `invalidExplicit`.

| Prioridad | Condición | Resultado |
| ---: | --- | --- |
| 1 | Se eligió un comodato específico válido | Se conserva la selección explícita. |
| 2 | No hay explícito y existe exactamente un comodato para la línea comercial | Se aplica ese comodato. |
| 3 | No hay resultado por línea y existe exactamente un comodato general | Se aplica el general. |
| 4 | No hay candidato único | No se asigna comodato. |

Los nombres de clave `general` y `General (heredado)` se reconocen como grupo
general. Si hay más de un candidato general, el servicio no elige uno de forma
arbitraria y devuelve `none`.

## Opciones de la interfaz de productos

- **Resolver automáticamente** deja que el servicio aplique la prioridad.
- **Sin comodato** usa un estado explícito (`sinComodato`), distinto de una
  resolución automática que no encontró candidato.
- **Comodato específico** permite seleccionar uno de los comodatos disponibles
  para el cliente y la línea.

Si un producto requiere comodato y no hay uno resuelto, la validación informa
`COMODATO_REQUIRED`. Si la selección está marcada como inválida, informa
`COMODATO_NOT_ALLOWED` antes de ejecutar.

## Límite de validez actual

Cuando el cliente ya contiene asociaciones para su línea o generales, una
selección explícita debe pertenecer a esas asociaciones. Cuando no hay ninguna
asociación cargada, el servicio acepta por ahora el comodato explícito para no
producir un falso negativo con datos incompletos. Esto no equivale a una
validación completa de pertenencia IA1 y debe cerrarse al disponer del maestro
persistido de cliente–comodato–línea.

## Datos y gestión pendientes

El catálogo IA1 migrado tiene 0 comodatos porque la fuente versionada no los
incluye. La selección actual se puede ejercitar con clientes Demo; todavía no
existe CRUD persistente para agregar, quitar, guardar, detectar duplicados o
asociar comodatos a clientes y líneas. Tampoco se importa el campo Desktop
`codigo_producto` como código de producto: corresponde al contexto de
comodato.

La siguiente implementación debe persistir explícitamente:

```text
clienteId + lineId (o general) + comodatoId + código + nombre + vigencia
```

sin usar `null` como sustituto ambiguo de «Sin comodato».
