import 'package:webview_flutter/webview_flutter.dart';

import 'automy_web_controller.dart';

final class WebViewSessionService {
  WebViewSessionService(this._webController);

  final AutomyWebController _webController;
  WebViewCookieManager? _cookieManager;

  /// No lee ni registra cookies: el estado se conserva de forma nativa.
  Future<void> clearSession() async {
    final cookieManager = _cookieManager ??= WebViewCookieManager();
    await Future.wait([
      cookieManager.clearCookies(),
      _webController.clearLocalStorage(),
      _webController.clearCache(),
    ]);
  }
}
