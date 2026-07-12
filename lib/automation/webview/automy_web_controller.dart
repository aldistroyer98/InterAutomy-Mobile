import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/security/webview_security_policy.dart';
import '../engine/automation_exception.dart';
import 'portal_diagnostics.dart';

/// Mantiene el WebView fuera de las pantallas y exige la política de origen.
final class AutomyWebController {
  final ValueNotifier<PortalDiagnostics> diagnostics = ValueNotifier(
    const PortalDiagnostics(),
  );

  WebViewController? _controller;
  WebViewSecurityPolicy? _policy;

  WebViewController get controller {
    final value = _controller;
    if (value == null) {
      throw const AutomationException(
        'Abra primero el navegador integrado de Automy.',
        code: 'WEBVIEW_NOT_READY',
      );
    }
    return value;
  }

  Uri? get currentUri => diagnostics.value.url;
  bool get isBound => _controller != null;

  void bind(WebViewController controller, WebViewSecurityPolicy policy) {
    _controller = controller;
    _policy = policy;
  }

  void unbind() => _controller = null;

  Future<void> openPortal(WebViewSecurityPolicy policy) async {
    final portal = policy.portalUrl;
    if (portal == null || !policy.isAllowedUri(portal)) {
      throw const AutomationException(
        'Configura una URL HTTPS de Automy antes de abrir el portal.',
        code: 'PORTAL_URL_REQUIRED',
      );
    }
    _policy = policy;
    await controller.loadRequest(portal);
  }

  bool mayNavigate(Uri uri) => _policy?.isAllowedUri(uri) ?? false;
  bool mayRunJavaScript() => _policy?.canRunJavaScript(currentUri) ?? false;

  Future<void> reload() => controller.reload();
  Future<bool> canGoBack() => controller.canGoBack();
  Future<void> goBack() => controller.goBack();
  Future<void> clearCache() => controller.clearCache();
  Future<void> clearLocalStorage() => controller.clearLocalStorage();

  void pageStarted(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    diagnostics.value = diagnostics.value.copyWith(
      url: uri,
      loadingProgress: 1,
      clearError: true,
    );
  }

  void pageFinished(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    diagnostics.value = diagnostics.value.copyWith(
      url: uri,
      loadingProgress: 100,
    );
  }

  void urlChanged(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    diagnostics.value = diagnostics.value.copyWith(url: uri);
  }

  void progressChanged(int progress) {
    diagnostics.value = diagnostics.value.copyWith(
      loadingProgress: progress.clamp(0, 100).toInt(),
    );
  }

  void webError(String description) {
    diagnostics.value = diagnostics.value.copyWith(lastError: description);
  }

  void updateDiagnostics(PortalDiagnostics diagnostics) {
    this.diagnostics.value = diagnostics;
  }

  void dispose() => diagnostics.dispose();
}
