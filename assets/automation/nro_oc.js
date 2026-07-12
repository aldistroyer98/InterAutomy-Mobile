(function () {
  'use strict';
  const api = window.__interautomyAutomation;

  function validationState(element) {
    const describedBy = String(element.getAttribute('aria-describedby') || '')
      .split(/\s+/).filter(Boolean).slice(0, 6);
    const describedError = describedBy.some(function (id) {
      const node = element.ownerDocument.getElementById(id);
      return Boolean(node && api.visible(node) && api.normalizedText(node.textContent).length > 0);
    });
    const classSignal = /error|invalid|danger|has-error/i.test(String(element.className || '')) ||
      Boolean(element.closest('.error, .invalid, .has-error, [data-status="error"]'));
    const nearby = element.parentElement && element.parentElement.querySelector(
      '[role="alert"], .error-message, .field-error, [data-error]'
    );
    return {
      invalid: element.getAttribute('aria-invalid') === 'true' || classSignal || describedError ||
        Boolean(nearby && api.visible(nearby)),
      signal: element.getAttribute('aria-invalid') === 'true' ? 'aria-invalid' :
        describedError ? 'aria-describedby' : classSignal ? 'error-class' :
        nearby ? 'nearby-error' : ''
    };
  }

  function safeSecondaryFocus(element) {
    const documentRoot = element.ownerDocument;
    const target = Array.from(documentRoot.querySelectorAll(
      'button:not([disabled]), a[href], select:not([disabled]), input:not([disabled])'
    )).find(function (candidate) {
      return candidate !== element && candidate.type !== 'submit' && api.visible(candidate);
    });
    if (target) target.focus({ preventScroll: true });
    else element.blur();
  }

  try {
    const found = api.findFirstSelectorAcrossRoots(payload.alternatives || []);
    if (!found) return api.fail('SELECTOR_NOT_FOUND', 'No se encontró el campo NRO OC', false, {});
    const element = found.element;
    const elementTag = String(element.tagName || '').toLocaleLowerCase();
    if (!['input', 'textarea'].includes(elementTag)) {
      return api.fail('PAGE_NOT_SUPPORTED', 'El selector NRO OC no corresponde a un control editable', false, {});
    }
    if (!api.visible(element)) return api.fail('FIELD_NOT_VISIBLE', 'El campo NRO OC no está visible', false, {});
    if (!api.enabled(element)) return api.fail('FIELD_DISABLED', 'El campo NRO OC no está habilitado', true, {});
    const expected = String(payload.value || '');
    const metadata = {
      logicalKey: payload.logicalKey,
      alternativeIndex: found.alternativeIndex,
      elementType: String(element.type || 'text').slice(0, 30),
      tag: elementTag,
      sameOrigin: true,
      insideShadowDom: found.insideShadowDom === true,
      insideIframe: found.insideIframe === true
    };
    if (payload.action === 'clear') {
      element.focus();
      api.setNativeValue(element, '');
      api.dispatchInputEvents(element);
      window.__interautomyNroOcState = null;
      return api.ok('NRO_OC_CLEARED', 'Prueba NRO OC limpiada', Object.assign(metadata, {
        actualMatches: api.readValue(element) === ''
      }));
    }
    if (payload.action === 'verify') {
      const state = window.__interautomyNroOcState || { appliedAt: 0, firstVerifiedAt: 0 };
      const matches = api.readValue(element) === expected;
      if (!matches) {
        return api.fail(payload.controlledFramework === true ? 'CONTROLLED_INPUT_REJECTED' : 'INPUT_STATE_NOT_PERSISTED', 'El valor NRO OC no persistió', false, Object.assign(metadata, {
          actualMatches: false
        }));
      }
      if (api.domStableForMs() < Number(payload.domStableMs || 350)) {
        return api.fail('DOM_STABILITY_PENDING', 'Esperando estabilidad del DOM', true, metadata);
      }
      if (!state.firstVerifiedAt) {
        safeSecondaryFocus(element);
        state.firstVerifiedAt = Date.now();
        window.__interautomyNroOcState = state;
        return api.fail('SECOND_STABILITY_PENDING', 'Esperando segunda estabilización', true, metadata);
      }
      if (Date.now() - state.firstVerifiedAt < Number(payload.secondPersistenceMs || 500) ||
          api.domStableForMs() < Number(payload.domStableMs || 350)) {
        return api.fail('SECOND_STABILITY_PENDING', 'Esperando segunda estabilización', true, metadata);
      }
      const fieldValidation = validationState(element);
      if (fieldValidation.invalid) {
        return api.fail('FIELD_VALIDATION_ERROR', 'Automy mostró una señal de validación para NRO OC', false, Object.assign(metadata, {
          validationSignal: fieldValidation.signal,
          actualMatches: true
        }));
      }
      return api.ok('NRO_OC_VERIFIED', 'NRO OC verificado después de dos estabilizaciones', Object.assign(metadata, {
        actualMatches: true,
        persistedAfterBlur: true,
        persistedAfterSecondStability: true,
        validationError: false
      }));
    }
    element.scrollIntoView({ block: 'center', inline: 'nearest' });
    element.focus();
    api.setNativeValue(element, expected);
    element.dispatchEvent(new Event('input', { bubbles: true, composed: true }));
    element.dispatchEvent(new Event('change', { bubbles: true, composed: true }));
    element.blur();
    window.__interautomyNroOcState = {
      appliedAt: Date.now(), firstVerifiedAt: 0
    };
    const matches = api.readValue(element) === expected;
    return matches
      ? api.ok('NRO_OC_APPLIED', 'NRO OC aplicado; requiere doble verificación', Object.assign(metadata, {
          actualMatches: true
        }))
      : api.fail('CONTROLLED_INPUT_REJECTED', 'El control rechazó el valor NRO OC', false, Object.assign(metadata, {
          actualMatches: false
        }));
  } catch (_) {
    return api.fail('UNKNOWN_ERROR', 'Falló la operación NRO OC', false, {});
  }
})(payload)
