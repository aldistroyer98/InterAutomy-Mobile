# Alcance de Mercado en móvil

## Decisión de esta fase

**Mercado/SEACE está fuera de alcance.** No se añade navegación, modelo,
catálogo, automatización ni integración remota para ese módulo en
InterAutomy-Mobile.

La referencia Desktop IA1 menciona componentes Mercado/SEACE como no portables
al MVP móvil de pedidos. No se ha aportado una especificación funcional ni una
fuente de datos versionada que permita trasladarlo sin inventar comportamiento.

## Motivos

- El objetivo actual es estabilizar Cliente → Productos → Ejecución Demo →
  Historial y eliminar el ciclo de providers.
- Mercado requeriría alcance de producto, modelo de datos, autorización y
  validación propios.
- No se debe usar Selenium, ChromeDriver, controles por coordenadas, servicios
  de accesibilidad, un servidor ni un agente Windows para suplir esa ausencia.
- No existe evidencia para marcar Mercado como necesario para la ejecución
  actual de pedidos en móvil.

## Condiciones para una fase posterior

Antes de incluirlo se requiere una decisión documentada sobre usuarios,
operaciones permitidas, fuentes autorizadas, datos sensibles, persistencia,
errores, pruebas Android y el límite entre asistencia WebView y automatización.
Esa decisión deberá revisar de nuevo la matriz de paridad y no debe implicar un
envío automático a Automy por defecto.
