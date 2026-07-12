(function () {
  'use strict';
  const api = window.__interautomyAutomation;
  try {
    let topLevelNroOc = Boolean(api.findFirstSelector(payload.nroOcAlternatives || []));
    const frames = Array.from(document.querySelectorAll('iframe, frame')).slice(0, 20).map((frame) => {
      let origin = 'unknown';
      try {
        const source = new URL(frame.src || location.href, location.href);
        origin = source.origin === location.origin ? 'sameOrigin' : 'crossOrigin';
        if (origin === 'sameOrigin' && frame.contentDocument &&
            api.findFirstSelector(payload.nroOcAlternatives || [], frame.contentDocument)) topLevelNroOc = true;
      } catch (_) {
        origin = 'crossOrigin';
      }
      return {
        origin: origin,
        source: api.sanitizedUrl(frame.src || ''),
        name: String(frame.name || '').slice(0, 60),
        id: String(frame.id || '').slice(0, 60),
        visible: api.visible(frame)
      };
    });
    return api.ok('IFRAME_DETECTION_COMPLETED', 'Iframes inspeccionados', {
      frames: frames,
      nroOcCrossOrigin: !topLevelNroOc && frames.some((frame) => frame.origin === 'crossOrigin')
    });
  } catch (_) {
    return api.fail('IFRAME_DETECTION_FAILED', 'No se pudieron inspeccionar los iframes', false, {});
  }
})(payload)
