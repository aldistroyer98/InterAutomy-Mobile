import 'package:webview_flutter/webview_flutter.dart';

import 'automy_web_controller.dart';

final class WebViewSessionService {
  WebViewSessionService(this._webController);

  final AutomyWebController _webController;
  final WebViewCookieManager _cookieManager = WebViewCookieManager();

  /// No lee ni registra cookies: el estado se conserva de forma nativa.
  Future<void> clearSession() async {
    await Future.wait([
      _cookieManager.clearCookies(),
      _webController.clearLocalStorage(),
      _webController.clearCache(),
    ]);
  }
}
