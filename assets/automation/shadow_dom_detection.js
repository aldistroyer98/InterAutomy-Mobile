(function () {
  'use strict';
  const api = window.__interautomyAutomation;
  try {
    const maximumDepth = 6;
    const maximumNodes = 1500;
    const maximumTimeMs = 40;
    const started = performance.now();
    const queue = [{ root: document, depth: 0 }];
    const hosts = [];
    let count = 0;
    let inputCount = 0;
    let possibleNroOc = false;
    let visited = 0;
    let maxDepth = 0;
    let truncated = false;
    while (queue.length) {
      const current = queue.shift();
      const nodes = current.root.querySelectorAll('*');
      for (const node of nodes) {
        visited += 1;
        if (visited > maximumNodes || performance.now() - started > maximumTimeMs) {
          truncated = true;
          queue.length = 0;
          break;
        }
        if (!node.shadowRoot) continue;
        count += 1;
        maxDepth = Math.max(maxDepth, current.depth + 1);
        hosts.push(String(node.localName || 'unknown').slice(0, 40));
        inputCount += node.shadowRoot.querySelectorAll('input').length;
        if (api.findFirstSelector(payload.nroOcAlternatives || [], node.shadowRoot)) possibleNroOc = true;
        if (current.depth + 1 < maximumDepth) queue.push({ root: node.shadowRoot, depth: current.depth + 1 });
        else truncated = true;
      }
    }
    return api.ok('SHADOW_DOM_DETECTION_COMPLETED', 'Shadow DOM abierto inspeccionado', {
      count: count,
      hosts: Array.from(new Set(hosts)).slice(0, 20),
      maxDepth: maxDepth,
      inputCount: inputCount,
      possibleNroOc: possibleNroOc,
      truncated: truncated
    });
  } catch (_) {
    return api.fail('SHADOW_DOM_DETECTION_FAILED', 'No se pudo inspeccionar Shadow DOM', false, {});
  }
})(payload)
