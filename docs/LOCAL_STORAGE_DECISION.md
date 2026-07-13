# Decisión de persistencia local

Decisión actual: conservar `LocalDomainStore` JSON endurecido. No introducir
Drift en esta fase.

## Comparación

| Criterio | JSON endurecido | Drift |
|---|---|---|
| Alcance actual | Un documento pequeño de clientes locales, instituciones, historial y perfiles | Varias tablas y consultas indexadas |
| Escritura | Cola en proceso, temporal con flush, rotación atómica y backup | Transacciones ACID de SQLite |
| Integridad | Esquema v2, checksum SHA-256, validación tipada y recuperación de backup | Tipos, constraints, WAL e integridad de SQLite |
| Migraciones | Funciones explícitas v0/v1→v2 | Migraciones SQL versionadas |
| Consultas | Carga completa en memoria; suficiente en el volumen actual | Filtrado/paginación eficiente sin cargar todo |
| Complejidad | Sin nueva dependencia ni código generado | Dependencia, generación, esquema y estrategia de migración adicionales |
| Concurrencia | Un escritor dentro del proceso | Mejor para múltiples transacciones y lectores |
| Recuperación | Último documento válido y backup anterior | Herramientas y garantías maduras de SQLite, pero requiere backup propio |

## Garantías implementadas

1. El JSON se serializa primero en `interautomy_data.json.tmp` y se hace
   `flush`.
2. El principal anterior se renombra a `.bak`; el temporal se renombra al
   principal. No se borra el principal antes de conservarlo.
3. El esquema v2 incluye checksum SHA-256 canónico.
4. Lectura corrupta intenta `.bak`, valida checksum/esquema y repara el
   principal; si ambos fallan devuelve `LocalDomainStoreException` tipada.
5. Las escrituras se serializan y trabajan sobre una copia; una escritura
   interrumpida no contamina la caché confirmada.
6. Se prueban JSON truncado, checksum alterado, ambos documentos corruptos,
   migraciones v0/v1, concurrencia, backup físico y cierre simulado.

## Criterios objetivos para migrar a Drift

Se abrirá una decisión de arquitectura si se cumple al menos uno:

- archivo principal supera 5 MiB de forma sostenida;
- historial supera 10,000 ejecuciones o perfiles superan 1,000;
- carga o búsqueda local P95 supera 100 ms en el Galaxy objetivo;
- se necesita paginación, agregación o búsqueda por múltiples campos sin
  cargar todo el documento;
- aparece más de un escritor/proceso o sincronización en segundo plano;
- una operación requiere actualizar subconjuntos grandes con frecuencia;
- dos migraciones JSON consecutivas producen fallos recuperables en datos
  reales;
- requisitos regulatorios exigen constraints, transacciones o auditoría por
  fila.

Antes de migrar se exigirá exportación/rollback, importación idempotente del
JSON v2, pruebas con copia de producción sanitizada y medición en Galaxy A26.
