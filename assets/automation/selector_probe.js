(function () {
  'use strict';
  const api = window.__interautomyAutomation;
  try {
    const found = api.findFirstSelector(payload.alternatives || []);
    if (found) {
      if (window.__interautomySelectorObserver) {
        window.__interautomySelectorObserver.disconnect();
        window.__interautomySelectorObserver = null;
      }
      return api.ok('SELECTOR_FOUND', 'Campo NRO OC detectado', {
        success: true,
        code: 'SELECTOR_FOUND',
        logicalKey: payload.logicalKey,
        alternativeIndex: found.alternativeIndex,
        visible: api.visible(found.element),
        enabled: api.enabled(found.element),
        version: payload.version
      });
    }
    if (!window.__interautomySelectorObserver && document.documentElement) {
      window.__interautomySelectorObserver = new MutationObserver(function () {});
      window.__interautomySelectorObserver.observe(document.documentElement, {
        childList: true, subtree: true, attributes: true
      });
    }
    return api.fail('SELECTOR_PENDING', 'Campo NRO OC aún no disponible', true, {
      success: false,
      code: 'SELECTOR_PENDING',
      logicalKey: payload.logicalKey,
      visible: false,
      enabled: false,
      version: payload.version
    });
  } catch (_) {
    return api.fail('SELECTOR_PROBE_FAILED', 'Falló la detección del campo NRO OC', false, {});
  }
})(payload)
