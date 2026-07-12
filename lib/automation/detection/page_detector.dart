import '../javascript/javascript_runner.dart';
import '../webview/portal_diagnostics.dart';

enum PortalPage {
  unknown,
  login,
  home,
  clientForm,
  productForm,
  review,
  success,
  error,
  sessionExpired,
}

final class PageDetector {
  PageDetector(this._runner);

  final JavascriptRunner _runner;

  Future<PortalDiagnostics> inspect(PortalDiagnostics previous) async {
    final result = await _runner.run('diagnostics');
    if (!result.success) {
      return previous.copyWith(lastError: result.message);
    }
    final data = result.data;
    final url = Uri.tryParse(data['url']?.toString() ?? '') ?? previous.url;
    final title = data['title']?.toString().trim();
    final page = detect(
      url: url,
      title: title ?? previous.title,
      hasPasswordInput: data['hasPasswordInput'] == true,
      hasOrderNumber: data['hasOrderNumber'] == true,
      hasCompleteButton: data['hasCompleteButton'] == true,
    );
    return previous.copyWith(
      url: url,
      title: title == null || title.isEmpty ? 'Sin título' : title,
      javascriptAvailable: true,
      cookiesAvailable: data['cookieEnabled'] == true,
      iframeCount: _intValue(data['iframes']),
      fileInputCount: _intValue(data['fileInputs']),
      popupLinkCount: _intValue(data['popupLinks']),
      page: page,
      engineVersion: _engineFromUserAgent(data['userAgent']?.toString()),
      clearError: true,
    );
  }

  PortalPage detect({
    required Uri? url,
    required String title,
    required bool hasPasswordInput,
    required bool hasOrderNumber,
    required bool hasCompleteButton,
  }) {
    final signal = '${url?.path ?? ''} $title'.toLowerCase();
    if (hasPasswordInput ||
        signal.contains('login') ||
        signal.contains('iniciar sesión')) {
      return PortalPage.login;
    }
    if (signal.contains('sesión expirada') ||
        signal.contains('session expired')) {
      return PortalPage.sessionExpired;
    }
    if (signal.contains('error')) {
      return PortalPage.error;
    }
    if (signal.contains('solicitud complet') ||
        signal.contains('pedido enviado')) {
      return PortalPage.success;
    }
    if (hasOrderNumber || signal.contains('nro oc')) {
      return PortalPage.clientForm;
    }
    if (hasCompleteButton) {
      return PortalPage.review;
    }
    if (signal.contains('producto') || signal.contains('tabla de pedidos')) {
      return PortalPage.productForm;
    }
    if (signal.contains('inicio') || signal.contains('procesos')) {
      return PortalPage.home;
    }
    return PortalPage.unknown;
  }

  static int _intValue(Object? value) => switch (value) {
    int value => value,
    num value => value.toInt(),
    _ => 0,
  };

  static String _engineFromUserAgent(String? value) {
    if (value == null || value.isEmpty) return 'WebView Android del sistema';
    final match = RegExp(r'(Chrome/[0-9.]+)').firstMatch(value);
    return match?.group(1) ?? 'WebView Android del sistema';
  }
}
