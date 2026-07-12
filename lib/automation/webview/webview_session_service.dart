import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../detection/page_detector.dart';
import '../session/session_validation_result.dart';
import 'automy_web_controller.dart';

final class WebViewSessionService {
  WebViewSessionService(this._webController);

  final AutomyWebController _webController;
  WebViewCookieManager? _cookieManager;
  static const _restartExpectationKey =
      'validation.session_expected_after_restart';
  final ValueNotifier<SessionValidationResult> validation = ValueNotifier(
    const SessionValidationResult(),
  );
  late final Future<void> _initialization = _initialize();
  bool _expectedAfterRestart = false;
  bool _closedWhileActive = false;
  bool _backgroundedWhileActive = false;

  Future<void> _initialize() async {
    final preferences = await SharedPreferences.getInstance();
    _expectedAfterRestart =
        preferences.getBool(_restartExpectationKey) ?? false;
    await preferences.remove(_restartExpectationKey);
  }

  Future<void> observePage(
    PortalPage page, {
    required bool persistSession,
  }) async {
    await _initialization;
    final active = switch (page) {
      PortalPage.home ||
      PortalPage.processList ||
      PortalPage.clientForm ||
      PortalPage.productForm ||
      PortalPage.review ||
      PortalPage.success => true,
      _ => false,
    };
    final expired = page == PortalPage.sessionExpired;
    final current = validation.value;
    validation.value = current.copyWith(
      sessionDetected: active,
      persistedAfterPortalClose:
          current.persistedAfterPortalClose || (active && _closedWhileActive),
      persistedAfterBackground:
          current.persistedAfterBackground ||
          (active && _backgroundedWhileActive),
      persistedAfterAppRestart:
          current.persistedAfterAppRestart || (active && _expectedAfterRestart),
      expired: expired,
      cookiesCleared: active ? false : current.cookiesCleared,
      notes: active
          ? 'Sesión inferida por página autenticada; no se leyeron cookies.'
          : expired
          ? 'El portal mostró una señal de sesión expirada.'
          : current.notes,
      timestamp: DateTime.now(),
    );
    if (active && persistSession) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_restartExpectationKey, true);
    }
    if (active) {
      _closedWhileActive = false;
      _backgroundedWhileActive = false;
      _expectedAfterRestart = false;
    }
  }

  void portalClosed() {
    _closedWhileActive = validation.value.sessionDetected;
  }

  void appPaused() {
    _backgroundedWhileActive = validation.value.sessionDetected;
  }

  void markLogoutVerified() {
    validation.value = validation.value.copyWith(
      sessionDetected: false,
      logoutVerified: true,
      notes: 'Logout verificado manualmente por el usuario.',
      timestamp: DateTime.now(),
    );
  }

  /// No lee ni registra cookies: el estado se conserva de forma nativa.
  Future<void> clearSession() async {
    final cookieManager = _cookieManager ??= WebViewCookieManager();
    await Future.wait([
      cookieManager.clearCookies(),
      _webController.clearLocalStorage(),
      _webController.clearCache(),
    ]);
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_restartExpectationKey);
    validation.value = validation.value.copyWith(
      sessionDetected: false,
      cookiesCleared: true,
      notes: 'Cookies, caché y almacenamiento web eliminados.',
      timestamp: DateTime.now(),
    );
  }

  void dispose() => validation.dispose();
}
