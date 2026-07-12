(function () {
  'use strict';
  const api = window.__interautomyAutomation;
  try {
    const found = api.findFirstSelector(payload.alternatives || []);
    if (!found) return api.fail('SELECTOR_NOT_FOUND', 'No se encontró el campo NRO OC', false, {});
    const element = found.element;
    if (!api.visible(element)) return api.fail('FIELD_NOT_VISIBLE', 'El campo NRO OC no está visible', true, {});
    if (!api.enabled(element)) return api.fail('FIELD_DISABLED', 'El campo NRO OC no está habilitado', true, {});
    const expected = String(payload.value || '');
    if (payload.action === 'clear') {
      element.focus();
      api.setNativeValue(element, '');
      api.dispatchInputEvents(element);
      return api.ok('NRO_OC_CLEARED', 'Prueba NRO OC limpiada', {
        logicalKey: payload.logicalKey,
        alternativeIndex: found.alternativeIndex,
        actualMatches: api.readValue(element) === ''
      });
    }
    if (payload.action === 'verify') {
      const state = window.__interautomyNroOcState || { appliedAt: 0, expected: expected };
      const elapsed = Date.now() - state.appliedAt;
      const matches = api.readValue(element) === expected;
      if (elapsed < Number(payload.persistenceMs || 500)) {
        return api.fail('VALUE_PERSISTENCE_PENDING', 'Esperando persistencia del valor NRO OC', true, {
          logicalKey: payload.logicalKey,
          alternativeIndex: found.alternativeIndex,
          actualMatches: matches
        });
      }
      return matches
        ? api.ok('NRO_OC_VERIFIED', 'NRO OC verificado', {
            logicalKey: payload.logicalKey,
            alternativeIndex: found.alternativeIndex,
            actualMatches: true
          })
        : api.fail(payload.controlledFramework === true ? 'CONTROLLED_INPUT_REJECTED' : 'INPUT_STATE_NOT_PERSISTED', 'El valor NRO OC no persistió', false, {
            logicalKey: payload.logicalKey,
            alternativeIndex: found.alternativeIndex,
            actualMatches: false
          });
    }
    element.scrollIntoView({ block: 'center', inline: 'nearest' });
    element.focus();
    api.setNativeValue(element, expected);
    element.dispatchEvent(new Event('input', { bubbles: true, composed: true }));
    element.dispatchEvent(new Event('change', { bubbles: true, composed: true }));
    element.blur();
    window.__interautomyNroOcState = { appliedAt: Date.now(), expected: expected };
    const matches = api.readValue(element) === expected;
    return matches
      ? api.ok('NRO_OC_APPLIED', 'NRO OC aplicado; requiere verificación de persistencia', {
          logicalKey: payload.logicalKey,
          alternativeIndex: found.alternativeIndex,
          actualMatches: true
        })
      : api.fail('CONTROLLED_INPUT_REJECTED', 'El control rechazó el valor NRO OC', false, {
          logicalKey: payload.logicalKey,
          alternativeIndex: found.alternativeIndex,
          actualMatches: false
        });
  } catch (_) {
    return api.fail('NRO_OC_FAILED', 'Falló la operación NRO OC', false, {});
  }
})(payload)
