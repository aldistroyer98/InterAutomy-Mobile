(function (payload) {
  const inspection = window.__interautomyAutomation.inspectPage();
  return { success: true, code: 'DIAGNOSTICS_READY', message: 'Diagnóstico actualizado.', data: inspection };
})(payload)
