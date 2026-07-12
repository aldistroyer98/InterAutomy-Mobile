abstract final class AppConfig {
  static const appName = 'InterAutomy';
  static const defaultPortalUrl = '';
  // Conservados para el cliente HTTP inactivo heredado; no intervienen en WebView.
  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 20);
  static const demoStepDuration = Duration(milliseconds: 350);
  static const workflowVersion = 'flutter3-webview-1';
  static const selectorVersion = 'automy-dom-1';
  static const fingerprintVersion = 'automy-fingerprint-1';
  static const allowAutomaticSubmission = false;
}
