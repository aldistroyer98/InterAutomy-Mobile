(function () {
  'use strict';
  const api = window.__interautomyAutomation;
  try {
    const inputs = document.querySelectorAll('input');
    const buttons = document.querySelectorAll('button, [role="button"]');
    const pageSignals = [];
    const selectorKeys = [];
    const bodyText = api.normalizedText((document.body && document.body.innerText || '').slice(0, 1600));
    if (document.querySelector('input[type="password"]')) pageSignals.push('login');
    if (/sesion (expirada|caducada)|session expired/.test(bodyText)) pageSignals.push('sessionExpired');
    if (/error al procesar|ocurrio un error|fallo|rechazado/.test(bodyText)) pageSignals.push('error');
    if (/solicitud.{0,80}(enviada|registrada|completada)|pedido.{0,80}(registrado|enviado|completado)/.test(bodyText)) pageSignals.push('success');
    if (document.querySelector('[data-page="review"], [data-testid="review-page"]') || /revis(ar|ion).{0,80}(solicitud|pedido)/.test(bodyText)) pageSignals.push('review');
    const nro = api.findFirstSelector(payload.nroOcAlternatives || []);
    if (nro) {
      selectorKeys.push('purchaseOrderNumber');
      pageSignals.push('clientForm');
    }
    if (document.querySelector('[data-page="process-list"], table[data-processes]') || /lista de procesos/.test(bodyText)) pageSignals.push('processList');
    if (document.querySelector('[data-page="home"]') || /bienvenido|inicio|procesos/.test(bodyText)) pageSignals.push('home');

    const links = Array.from(document.querySelectorAll('a[href]'));
    const externalLinks = links.filter((link) => {
      try { return new URL(link.href, location.href).origin !== location.origin; }
      catch (_) { return false; }
    });
    const targetBlankCount = document.querySelectorAll('a[target="_blank"]').length;
    return api.ok('DIAGNOSTIC_COMPLETED', 'Diagnóstico completado', {
      version: 'diagnostics-1',
      url: api.sanitizedUrl(location.href),
      title: String(document.title || '').slice(0, 120),
      userAgent: String(navigator.userAgent || '').slice(0, 180),
      structure: {
        forms: document.forms.length,
        inputs: inputs.length,
        selects: document.querySelectorAll('select').length,
        buttons: buttons.length,
        tables: document.querySelectorAll('table').length,
        fileInputs: document.querySelectorAll('input[type="file"]').length
      },
      storage: {
        sessionStorage: api.storageAvailable('sessionStorage'),
        localStorage: api.storageAvailable('localStorage'),
        cookies: navigator.cookieEnabled === true
      },
      popup: {
        detected: targetBlankCount > 0,
        targetBlankCount: targetBlankCount,
        externalLinkCount: externalLinks.length,
        ssoLinkCount: externalLinks.filter((link) => /login|signin|sso|oauth/i.test(link.href)).length
      },
      domStableForMs: api.domStableForMs(),
      pageSignals: Array.from(new Set(pageSignals)),
      selectorKeys: selectorKeys
    });
  } catch (_) {
    return api.fail('DIAGNOSTIC_FAILED', 'Diagnóstico fallido', false, {});
  }
})(payload)
