(function () {
  'use strict';
  const api = window.__interautomyAutomation;
  const started = performance.now();
  try {
    const alternatives = payload.alternatives || [];
    const roots = api.searchableRoots();
    const attempts = alternatives.map(function (_, index) {
      let location = null;
      for (const context of roots) {
        const found = api.findFirstSelector([alternatives[index]], context.root);
        if (found) {
          location = { element: found.element, context: context };
          break;
        }
      }
      const element = location && location.element;
      const tag = element ? String(element.tagName || '').toLocaleLowerCase() : '';
      const validControl = tag === 'input' || tag === 'textarea';
      return {
        index: index,
        found: Boolean(element && validControl),
        visible: Boolean(element && validControl && api.visible(element)),
        enabled: Boolean(element && validControl && api.enabled(element)),
        elementType: validControl ? String(element.type || 'text').slice(0, 30) : '',
        tag: validControl ? tag : '',
        sameOrigin: true,
        insideShadowDom: Boolean(location && location.context.insideShadowDom),
        insideIframe: Boolean(location && location.context.insideIframe)
      };
    });
    const found = api.findFirstSelectorAcrossRoots(alternatives);
    const element = found && found.element;
    const elementTag = element ? String(element.tagName || '').toLocaleLowerCase() : '';
    const validControl = elementTag === 'input' || elementTag === 'textarea';
    if (found && validControl) {
      if (window.__interautomySelectorObserver) {
        window.__interautomySelectorObserver.disconnect();
        window.__interautomySelectorObserver = null;
      }
      return api.ok('SELECTOR_FOUND', 'Campo NRO OC detectado', {
        success: true,
        code: 'SELECTOR_FOUND',
        logicalKey: payload.logicalKey,
        alternativeIndex: found.alternativeIndex,
        visible: api.visible(element),
        enabled: api.enabled(element),
        elementType: String(element.type || 'text').slice(0, 30),
        tag: elementTag,
        sameOrigin: true,
        insideShadowDom: found.insideShadowDom === true,
        insideIframe: found.insideIframe === true,
        elapsedMilliseconds: Math.round(performance.now() - started),
        alternatives: attempts,
        version: payload.version
      });
    }
    const closedHost = Array.from(document.querySelectorAll('[data-field="nro_oc"], [data-testid="nro-oc"]'))
      .some(function (node) {
        return !['input', 'textarea'].includes(node.localName) && !node.shadowRoot && node.localName.includes('-');
      });
    if (closedHost) {
      return api.fail('NRO_OC_CLOSED_SHADOW_ROOT', 'NRO OC puede estar dentro de un Shadow Root cerrado', false, {
        success: false,
        code: 'NRO_OC_CLOSED_SHADOW_ROOT',
        logicalKey: payload.logicalKey,
        alternatives: attempts,
        elapsedMilliseconds: Math.round(performance.now() - started),
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
      alternatives: attempts,
      elapsedMilliseconds: Math.round(performance.now() - started),
      visible: false,
      enabled: false,
      version: payload.version
    });
  } catch (_) {
    return api.fail('SELECTOR_PROBE_FAILED', 'Falló la detección del campo NRO OC', false, {});
  }
})(payload)
