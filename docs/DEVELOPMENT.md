# Desarrollo

## Preparación

```powershell
flutter doctor -v
flutter pub get
flutter run
```

El proyecto ya existe: no ejecutar `flutter create`. El repositorio desktop se
consulta solo como referencia y nunca se modifica desde este flujo.

## Convenciones

- Todo texto visible está en español.
- Dominio no importa Flutter.
- UI depende de providers, no de implementaciones de repositorio.
- HTTP, almacenamiento y reglas no viven en widgets.
- Mantener entidades inmutables y errores tipados.
- No añadir secretos ni endpoints funcionales no confirmados.
- No dejar TODO, pseudocódigo, botones inertes o imports sin uso.

## Validación local

```powershell
dart format .
flutter analyze
flutter test
flutter build apk --debug
flutter build appbundle --debug
```

La integración se ejecuta en Android:

```powershell
flutter devices
flutter test integration_test/app_flow_test.dart -d <android-device-id>
```

## Commits

Crear commits pequeños por responsabilidad. Antes de cada commit ejecutar
formato, análisis y pruebas relevantes. Revisar `git diff --check` y no incluir
artefactos de `build`, cachés, APK o AAB.

## Añadir una API

Actualizar primero `docs/API_INTEGRATION.md` y aprobar OpenAPI. Implementar DTOs
y mappers con pruebas de contrato, habilitar repositorios mediante composición
de providers y conservar el modo demo para desarrollo. Ningún widget debe
conocer Dio.

## Diagnóstico

Los fallos de validación deben reproducirse con pruebas de dominio. Los de UI,
con pruebas widget en tamaños compacto y expandido. Los distribuidos, con IDs
de correlación compartidos entre móvil, API y agente.
