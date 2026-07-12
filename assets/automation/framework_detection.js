(function () {
  'use strict';
  const api = window.__interautomyAutomation;
  try {
    const candidates = [];
    function add(name, confidence, signals) {
      if (signals.length) candidates.push({ name: name, confidence: confidence, signals: signals });
    }
    const react = [];
    if (window.__REACT_DEVTOOLS_GLOBAL_HOOK__) react.push('react-devtools-hook');
    if (document.querySelector('[data-reactroot], [data-reactid]')) react.push('react-root-attribute');
    if (document.getElementById('__next')) react.push('next-root');
    add('react', react.length > 1 ? 0.9 : 0.65, react);
    if (document.getElementById('__next') || window.__NEXT_DATA__) add('nextjs', 0.95, ['next-runtime']);
    const angular = [];
    if (document.querySelector('[ng-version]')) angular.push('ng-version');
    if (window.ng) angular.push('angular-runtime');
    add('angular', angular.length > 1 ? 0.95 : 0.75, angular);
    const vue = [];
    if (document.querySelector('[data-v-app]')) vue.push('vue-app-attribute');
    if (window.__VUE__ || window.__VUE_DEVTOOLS_GLOBAL_HOOK__) vue.push('vue-runtime');
    add('vue', vue.length > 1 ? 0.9 : 0.7, vue);
    if (!candidates.length && document.forms.length) add('html', 0.6, ['native-form']);
    candidates.sort((a, b) => b.confidence - a.confidence);
    return api.ok('FRAMEWORK_DETECTED', 'Framework inspeccionado',
      candidates[0] || { name: 'unknown', confidence: 0, signals: [] });
  } catch (_) {
    return api.fail('FRAMEWORK_DETECTION_FAILED', 'No se pudo detectar el framework', false, {});
  }
})(payload)
