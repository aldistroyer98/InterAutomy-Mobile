import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:interautomy_mobile/automation/detection/page_detector.dart';
import 'package:interautomy_mobile/automation/diagnostics/device_runtime_info.dart';
import 'package:interautomy_mobile/automation/diagnostics/diagnostic_models.dart';
import 'package:interautomy_mobile/automation/navigation/navigation_diagnostic_event.dart';
import 'package:interautomy_mobile/automation/webview/automy_web_controller.dart';
import 'package:interautomy_mobile/automation/webview/webview_session_service.dart';
import 'package:interautomy_mobile/core/security/webview_security_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'SessionValidationResult mide cierre y segundo plano sin cookies',
    () async {
      SharedPreferences.setMockInitialValues({});
      final service = WebViewSessionService(AutomyWebController());
      addTearDown(service.dispose);

      await service.observePage(PortalPage.login, persistSession: true);
      expect(service.validation.value.sessionDetected, isFalse);
      await service.observePage(PortalPage.clientForm, persistSession: true);
      expect(service.validation.value.sessionDetected, isTrue);

      service.portalClosed();
      await service.observePage(PortalPage.home, persistSession: true);
      expect(service.validation.value.persistedAfterPortalClose, isTrue);

      service.appPaused();
      await service.observePage(PortalPage.processList, persistSession: true);
      expect(service.validation.value.persistedAfterBackground, isTrue);
      expect(service.validation.value.toJson(), isNot(contains('cookies')));
    },
  );

  test('sesión expirada y logout se registran sin credenciales', () async {
    SharedPreferences.setMockInitialValues({});
    final service = WebViewSessionService(AutomyWebController());
    addTearDown(service.dispose);
    await service.observePage(PortalPage.sessionExpired, persistSession: false);
    expect(service.validation.value.expired, isTrue);
    service.markLogoutVerified();
    expect(service.validation.value.logoutVerified, isTrue);
    expect(service.validation.value.sessionDetected, isFalse);
  });

  test('navegación diagnóstica solo conserva URL sanitizada', () {
    final event = NavigationDiagnosticEvent(
      timestamp: DateTime.utc(2026, 7, 12),
      type: NavigationEventType.redirect,
      decision: 'block',
      reason: 'Host no autorizado',
      fromUrl: WebViewSecurityPolicy.displayUrl(
        Uri.parse('https://portal.example.test/start?token=secret#fragment'),
      ),
      toUrl: WebViewSecurityPolicy.displayUrl(
        Uri.parse('https://blocked.example.test/login?code=secret'),
      ),
      fromHost: 'portal.example.test',
      toHost: 'blocked.example.test',
    );
    final json = event.toJson().toString();
    expect(json, isNot(contains('token=')));
    expect(json, isNot(contains('code=')));
    expect(json, isNot(contains('secret')));
  });

  test('selector probe exporta metadatos, nunca valor', () {
    final probe = SelectorProbeResult.fromJson({
      'success': true,
      'code': 'SELECTOR_FOUND',
      'logicalKey': 'purchaseOrderNumber',
      'alternativeIndex': 0,
      'visible': true,
      'enabled': true,
      'elementType': 'text',
      'tag': 'input',
      'insideIframe': true,
      'alternatives': [
        {'index': 0, 'found': true, 'visible': true, 'enabled': true},
      ],
    });
    expect(probe.insideIframe, isTrue);
    expect(probe.alternatives.single.found, isTrue);
    expect(probe.toJson(), isNot(contains('value')));
  });

  test('información Android/WebView limita valores de plataforma', () {
    final info = DeviceRuntimeInfo.fromMap({
      'manufacturer': 'Example',
      'model': 'Fixture Device',
      'androidVersion': '16',
      'androidSdk': 36,
      'webViewVersion': '150.0',
      'webViewPackage': 'com.android.webview',
    });
    expect(info.androidSdk, 36);
    expect(info.webViewVersion, '150.0');
  });

  test('fixtures IA Flutter5 cubren redirección y estados NRO OC', () {
    const fixtures = [
      'redirect_authorized.html',
      'redirect_blocked.html',
      'nro_oc_reverted.html',
      'nro_oc_disabled.html',
      'nro_oc_hidden.html',
      'nro_oc_aria_invalid.html',
      'iframe_same_origin_v5.html',
      'shadow_dom_closed.html',
    ];
    for (final name in fixtures) {
      final source = File('test/fixtures/webview/$name').readAsStringSync();
      expect(source, isNot(contains('automy.pe')), reason: name);
      expect(source, isNot(contains('password=')), reason: name);
    }
  });

  test('script NRO OC implementa doble estabilidad y error localizado', () {
    final source = File('assets/automation/nro_oc.js').readAsStringSync();
    expect(source, contains('SECOND_STABILITY_PENDING'));
    expect(source, contains('FIELD_VALIDATION_ERROR'));
    expect(source, contains('aria-invalid'));
    expect(source, contains('aria-describedby'));
    expect(source, isNot(contains('document.body.innerText')));
    expect(source, isNot(contains('.submit(')));
  });
}
