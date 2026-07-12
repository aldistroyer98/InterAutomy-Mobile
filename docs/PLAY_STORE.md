# Preparación para Google Play

## Antes de publicar

- Cambiar a versión y build number aprobados.
- Configurar firma release fuera del repositorio y Play App Signing.
- Sustituir íconos y splash de plantilla por activos corporativos aprobados.
- Definir nombre, descripción, categoría, correo y URL de soporte.
- Preparar capturas de teléfono y tableta en español.
- Publicar política de privacidad y términos.
- Completar Seguridad de datos, clasificación de contenido y público objetivo.
- Verificar nivel de API objetivo vigente y requisitos de tamaño de página.
- Ejecutar pruebas en dispositivos físicos de distintos tamaños y versiones.

## Seguridad y datos

Declarar datos de cuenta, cliente, pedido, diagnóstico y telemetría según el
contrato final. El MVP demo no debe presentarse como integración productiva. No
subir secretos, almacenes de firma ni configuraciones privadas.

## Calidad de release

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build appbundle --release
```

Además se requieren pruebas de integración Android, accesibilidad, modo oscuro,
red lenta/sin red, rotación, restauración de proceso y actualización desde una
versión anterior.

## Canales

1. Internal testing para equipo técnico.
2. Closed testing con usuarios de negocio y agente staging.
3. Open testing solo si seguridad y soporte están listos.
4. Producción gradual con monitoreo y rollback.

## Riesgos pendientes

No publicar como producto operativo hasta disponer de API, autenticación,
agente Windows, persistencia remota, observabilidad, política de privacidad,
activos definitivos y firma release.
