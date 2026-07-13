# Formato y persistencia de perfiles móvil

## Estado actual

`OrderProfile`, `ProfileRepository` y `PersistentProfileRepository` están
implementados. Los perfiles se guardan en el documento privado
`interautomy_data.json` mediante `LocalDomainStore`; el documento raíz usa
`schemaVersion: 1` y una migración explícita desde el formato v0 sin versión.

La hoja de perfiles en Cliente permite guardar el pedido actual, cargarlo,
renombrarlo, duplicar el pedido actual y eliminar con confirmación. El
repositorio rechaza nombres duplicados sin distinguir mayúsculas ni espacios.
Todavía no hay un indicador de cambios sin guardar, por lo que la paridad de
perfiles sigue siendo parcial.

## Representación persistida actual

```json
{
  "schemaVersion": 1,
  "profiles": [
    {
      "id": "uuid-local",
      "name": "Perfil laboratorio norte",
      "client": { "id": "client-id", "name": "Nombre guardado" },
      "products": [],
      "createdAt": "2026-07-13T00:00:00.000Z",
      "updatedAt": "2026-07-13T00:00:00.000Z"
    }
  ]
}
```

El ejemplo es estructural. En la persistencia real, `client` es un snapshot
completo de sus campos (institución, condiciones, comentario, comodatos y
referencia de OC) y cada producto conserva línea, cantidad, precio, atributos
de verificación, comodato y expiración. El perfil no vuelve a consultar el
catálogo para poder cargarse si este cambia.

## Seguridad y archivos

- No se incluyen credenciales, cookies, tokens, secretos ni sesión WebView.
- La referencia de OC solo conserva URI, nombre visible y MIME; no se incorpora
  el contenido del documento al perfil.
- Los datos se escriben mediante un archivo temporal y reemplazo en el
  directorio de documentos de la app; no se usan `SharedPreferences` para estas
  colecciones.
- Un perfil con nombre duplicado produce `PROFILE_DUPLICATE`; un documento con
  esquema posterior produce un error controlado de compatibilidad.

## Compatibilidad con Desktop IA1

El Desktop usa perfiles JSON con versiones y metadatos de credenciales, pero
no existían perfiles operativos versionados en el commit IA1 que pudieran
migrarse de forma segura. Los perfiles móviles actuales no intentan importar
credenciales, keyring, cookies o rutas de Windows.

Antes de añadir interoperabilidad se debe definir una conversión explícita de
campos y revisar privacidad. No se deben tratar los perfiles móviles de esquema
1 como equivalentes binarios de los formatos Desktop v1/v2/v3.
