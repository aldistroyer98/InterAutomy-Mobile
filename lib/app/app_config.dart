abstract final class AppConfig {
  static const appName = 'InterAutomy';
  static const defaultPortalUrl = '';
  // Conservados para el cliente HTTP inactivo heredado; no intervienen en WebView.
  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 20);
  static const demoStepDuration = Duration(milliseconds: 350);
  static const workflowVersion = 'flutter4-nro-oc-1';
  static const selectorVersion = 'automy-nro-oc-2';
  static const fingerprintVersion = 'automy-fingerprint-2';
  static const diagnosticVersion = 'flutter4-diagnostic-1';
  static const selectorTimeout = Duration(seconds: 12);
  static const domIdleTimeout = Duration(seconds: 4);
  static const valuePersistenceTimeout = Duration(seconds: 3);
  static const diagnosticTimeout = Duration(seconds: 8);
  static const allowAutomaticSubmission = false;
}
