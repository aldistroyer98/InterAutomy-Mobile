(function (payload) {
  const api = window.__interautomyAutomation;
  const found = api.findFirstSelector(payload.alternatives);
  if (!found || !api.visible(found.element)) {
    return { success: false, code: 'SELECTOR_NOT_FOUND', message: 'No se encontró el campo requerido.', retryable: true, data: { selectorKey: payload.selectorKey } };
  }
  api.setNativeValue(found.element, String(payload.value || ''));
  api.dispatchInputEvents(found.element);
  const actual = String(found.element.value || '');
  const expected = String(payload.value || '');
  if (actual !== expected) {
    return { success: false, code: 'VALUE_NOT_VERIFIED', message: 'Automy no confirmó el valor del campo.', retryable: true, data: { selectorKey: payload.selectorKey } };
  }
  return { success: true, code: 'FIELD_UPDATED', message: 'Campo actualizado y verificado.', data: { selectorKey: payload.selectorKey, selector: found.selector } };
})(payload)
