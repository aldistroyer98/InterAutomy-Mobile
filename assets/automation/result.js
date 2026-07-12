(function (payload) {
  const api = window.__interautomyAutomation;
  const page = api.inspectPage(true);
  const text = page.text.toLocaleLowerCase();
  const success = /solicitud.{0,80}(complet|registrad|enviad)|pedido.{0,80}(complet|registrad|enviad)/.test(text) || !page.hasCompleteButton && /detalle.{0,80}solicitud/.test(text);
  const error = /error|no se pudo|rechazad/.test(text);
  return {
    success: true,
    code: success ? 'RESULT_SUCCESS' : error ? 'RESULT_ERROR' : 'RESULT_UNCONFIRMED',
    message: success ? 'Automy mostró una señal verificable de éxito.' : error ? 'Automy mostró un error.' : 'Resultado no confirmado.',
    data: { result: success ? 'success' : error ? 'error' : 'unknown', url: page.url }
  };
})(payload)
