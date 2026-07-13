# Validación tipada de pedidos

`OrderValidationService` concentra la validación previa y devuelve un
`ValidationResult`. El resultado contiene una lista inmutable de
`ValidationIssue`:

| Campo | Uso |
| --- | --- |
| `code` | Identificador estable para UI, pruebas y telemetría futura. |
| `field` | Campo o fila que necesita corrección. |
| `message` | Mensaje entendible para la persona usuaria. |
| `severity` | `error` o `warning`. |
| `correctiveAction` | Acción sugerida sin exponer una excepción técnica. |

`ValidationResult.valid` solo es verdadero cuando no existen errores. Las
advertencias no autorizan a convertir datos no verificados en datos válidos.

## Reglas implementadas

| Código | Regla |
| --- | --- |
| `CLIENT_REQUIRED` | Cliente con ID y nombre obligatorios. |
| `INSTITUTION_REQUIRED` | Institución de texto obligatoria en el cliente actual. |
| `LOCATION_REQUIRED` | Departamento, provincia, distrito y dirección obligatorios. |
| `CONTACT_REQUIRED` / `PHONE_INVALID` | Contacto y teléfono de al menos siete dígitos. |
| `PURCHASE_ORDER_OR_REASON_REQUIRED` | Debe existir NRO OC o motivo. |
| `PURCHASE_ORDER_FILE_REQUIRED` | Si hay NRO OC, la referencia `archivoOc` no puede quedar vacía. |
| `UNIT_REQUIRED` | Unidad obligatoria. |
| `START_TIME_REQUIRED` / `END_TIME_REQUIRED` / `SCHEDULE_INVALID` | Horarios obligatorios y no iguales. |
| `CURRENCY_REQUIRED` | Moneda obligatoria. |
| `FINAL_COMMENT_REQUIRED` | Comentario final obligatorio. |
| `PRODUCTS_REQUIRED` | Debe existir al menos un producto. |
| `PRODUCT_INVALID` / `LINE_REQUIRED` | Producto y línea por fila obligatorios. |
| `QUANTITY_INVALID` / `PRICE_REQUIRED` | Cantidad positiva y precio verificado/mayor que cero. |
| `COMODATO_REQUIRED` / `COMODATO_NOT_ALLOWED` | Comodato requerido o no permitido por cliente/línea. |
| `PRODUCT_CODE_UNAVAILABLE` / `PRODUCT_DETAILS_UNAVAILABLE` | Advertencias cuando IA1 no suministra código, presentación o categoría verificables. |

La pantalla de Ejecución permite validar antes de iniciar y presenta estas
incidencias. Un fallo al construir el gateway se transforma en
`EXECUTION_GATEWAY_INIT`, con mensaje accionable; el detalle sanitizado se
limita al modo desarrollador.

## Límites conocidos

- El modelo admite URI, nombre y MIME de un archivo OC seleccionado por SAF,
  pero la pantalla Cliente aún no conecta el selector; la regla actual solo
  puede comprobar que exista una referencia no vacía.
- Institución, ubicación y contacto aún viven en `Client`; no se valida una
  relación institucional persistida.
- El servicio no valida todavía las reglas completas de IGV, adelanto, servicio
  ni el orden cronológico real de horarios con un value object de hora.
- Para productos IA1 faltan precios y atributos de producto en la fuente. No se
  permite ejecutar con el precio `0` no verificado, pero la captura/autorización
  de esos datos aún requiere diseño de persistencia.

Las pruebas de servicio deben cubrir el código de incidencia y no depender del
texto visible, salvo cuando el mensaje sea parte del contrato de experiencia.
