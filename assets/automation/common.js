(function () {
  'use strict';

  const VERSION = 'flutter5-js-1';

  function associatedLabelControl(root) {
    const labels = Array.from(root.querySelectorAll('label'));
    for (const label of labels) {
      const text = normalizedText(label.textContent || '');
      if (!/\bnro\s*oc\b|orden de compra/.test(text)) continue;
      const control = label.control ||
        (label.htmlFor ? root.getElementById && root.getElementById(label.htmlFor) : null) ||
        label.querySelector('input, textarea');
      if (control) return control;
    }
    return null;
  }

  function ok(code, message, data) {
    return { success: true, code: code, message: message, data: data || {} };
  }

  function fail(code, message, retryable, details) {
    return {
      success: false,
      code: code,
      message: message,
      retryable: retryable === true,
      details: details || {},
      data: details || {}
    };
  }

  function findFirstSelector(alternatives, root) {
    const scope = root || document;
    for (let index = 0; index < (alternatives || []).length; index += 1) {
      try {
        if (alternatives[index] === '@associated-label:nro-oc') {
          const control = associatedLabelControl(scope);
          if (control) return { element: control, alternativeIndex: index };
          continue;
        }
        const element = scope.querySelector(alternatives[index]);
        if (element) return { element: element, alternativeIndex: index };
      } catch (_) {
        // Un selector inválido se ignora sin exponerlo en la respuesta.
      }
    }
    return null;
  }

  function searchableRoots() {
    const roots = [{ root: document, insideShadowDom: false, insideIframe: false }];
    const queue = [document];
    let visited = 0;
    while (queue.length && visited < 1200) {
      const root = queue.shift();
      for (const node of root.querySelectorAll('*')) {
        visited += 1;
        if (node.shadowRoot) {
          roots.push({ root: node.shadowRoot, insideShadowDom: true, insideIframe: false });
          queue.push(node.shadowRoot);
        }
        if (visited >= 1200) break;
      }
    }
    for (const frame of Array.from(document.querySelectorAll('iframe, frame')).slice(0, 20)) {
      try {
        if (frame.contentDocument) {
          roots.push({ root: frame.contentDocument, insideShadowDom: false, insideIframe: true });
        }
      } catch (_) {
        // Cross-origin: nunca se accede al documento.
      }
    }
    return roots;
  }

  function findFirstSelectorAcrossRoots(alternatives) {
    for (const context of searchableRoots()) {
      const found = findFirstSelector(alternatives, context.root);
      if (found) return Object.assign(found, context, { sameOrigin: true });
    }
    return null;
  }

  function visible(element) {
    if (!element || !element.isConnected) return false;
    const style = window.getComputedStyle(element);
    const rect = element.getBoundingClientRect();
    return style.visibility !== 'hidden' && style.display !== 'none' &&
      Number(style.opacity || 1) !== 0 && rect.width > 0 && rect.height > 0;
  }

  function enabled(element) {
    return Boolean(element) && !element.disabled &&
      element.getAttribute('aria-disabled') !== 'true' && !element.readOnly;
  }

  function setNativeValue(element, value) {
    const ownerWindow = element.ownerDocument && element.ownerDocument.defaultView || window;
    const prototype = String(element.tagName || '').toLocaleLowerCase() === 'textarea'
      ? ownerWindow.HTMLTextAreaElement.prototype
      : ownerWindow.HTMLInputElement.prototype;
    const descriptor = Object.getOwnPropertyDescriptor(prototype, 'value');
    if (descriptor && descriptor.set) descriptor.set.call(element, value);
    else element.value = value;
  }

  function dispatchInputEvents(element) {
    element.dispatchEvent(new Event('input', { bubbles: true, composed: true }));
    element.dispatchEvent(new Event('change', { bubbles: true, composed: true }));
    element.dispatchEvent(new FocusEvent('blur', { bubbles: true, composed: true }));
  }

  function readValue(element) {
    return element && 'value' in element ? String(element.value || '') : '';
  }

  function sanitizedUrl(raw) {
    try {
      const url = new URL(raw, location.href);
      if (url.protocol !== 'https:') return '';
      return url.protocol + '//' + url.host + url.pathname;
    } catch (_) {
      return '';
    }
  }

  function storageAvailable(name) {
    try {
      const storage = window[name];
      if (!storage) return false;
      const key = '__interautomy_probe__';
      storage.setItem(key, '1');
      storage.removeItem(key);
      return true;
    } catch (_) {
      return false;
    }
  }

  function normalizedText(value) {
    return String(value || '').toLocaleLowerCase()
      .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
      .replace(/\s+/g, ' ').trim();
  }

  if (!window.__interautomyOriginalOpen) {
    window.__interautomyOriginalOpen = window.open;
    window.open = function (rawUrl) {
      const safeUrl = sanitizedUrl(rawUrl || '');
      if (safeUrl && window.InterAutomyPopup &&
          typeof window.InterAutomyPopup.postMessage === 'function') {
        window.InterAutomyPopup.postMessage(safeUrl);
      }
      return null;
    };
  }

  if (!window.__interautomyDomTracker && document.documentElement) {
    window.__interautomyDomTracker = { lastMutationAt: Date.now(), count: 0 };
    const trackerObserver = new MutationObserver(function (records) {
      window.__interautomyDomTracker.lastMutationAt = Date.now();
      window.__interautomyDomTracker.count += records.length;
    });
    trackerObserver.observe(document.documentElement, {
      childList: true, subtree: true, attributes: true, characterData: true
    });
    window.__interautomyDomTracker.observer = trackerObserver;
  }

  window.__interautomyAutomation = Object.freeze({
    version: VERSION,
    ok: ok,
    fail: fail,
    findFirstSelector: findFirstSelector,
    findFirstSelectorAcrossRoots: findFirstSelectorAcrossRoots,
    searchableRoots: searchableRoots,
    visible: visible,
    enabled: enabled,
    setNativeValue: setNativeValue,
    dispatchInputEvents: dispatchInputEvents,
    readValue: readValue,
    sanitizedUrl: sanitizedUrl,
    storageAvailable: storageAvailable,
    normalizedText: normalizedText,
    domStableForMs: function () {
      return window.__interautomyDomTracker
        ? Math.max(0, Date.now() - window.__interautomyDomTracker.lastMutationAt)
        : 0;
    }
  });
})();
