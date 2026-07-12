(function () {
  'use strict';
  const api = window.__interautomyAutomation;
  try {
    const text = api.normalizedText((document.body && document.body.innerText || '').slice(0, 2400));
    const error = /error|fallo|no se pudo|rechazado/.test(text);
    const success = /solicitud.{0,80}(enviada|registrada|completada)|pedido.{0,80}(registrado|enviado|completado)|producto.{0,80}enviado/.test(text);
    const result = error ? 'error' : success ? 'success' : 'unknown';
    return api.ok(
      result === 'success' ? 'RESULT_SUCCESS' : result === 'error' ? 'RESULT_ERROR' : 'RESULT_UNKNOWN',
      result === 'success' ? 'Señal de éxito detectada' : result === 'error' ? 'Señal de error detectada' : 'Resultado desconocido',
      { result: result }
    );
  } catch (_) {
    return api.fail('RESULT_DETECTION_FAILED', 'Falló la detección de resultado', false, {});
  }
})(payload)
