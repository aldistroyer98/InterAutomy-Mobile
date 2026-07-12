import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:interautomy_mobile/app/app_config.dart';
import 'package:interautomy_mobile/automation/javascript/javascript_payload_encoder.dart';
import 'package:interautomy_mobile/automation/javascript/javascript_result.dart';
import 'package:interautomy_mobile/automation/selectors/selector_registry.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android WebView valida fixtures NRO OC sin enviar', (
    tester,
  ) async {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: WebViewWidget(controller: controller)),
      ),
    );

    await _loadFixture(controller, 'client_form.html');
    final probe = await _run(controller, 'selector_probe');
    expect(probe.code, 'SELECTOR_FOUND');
    expect(probe.data['visible'], isTrue);
    expect(probe.data['enabled'], isTrue);

    final applied = await _run(
      controller,
      'nro_oc',
      payload: _nroPayload('apply'),
    );
    expect(applied.code, 'NRO_OC_APPLIED');
    final verified = await _pollVerification(controller);
    expect(verified.code, 'NRO_OC_VERIFIED');

    await _loadFixture(controller, 'nro_oc_disabled.html');
    final disabled = await _run(controller, 'selector_probe');
    expect(disabled.data['enabled'], isFalse);

    await _loadFixture(controller, 'nro_oc_hidden.html');
    final hidden = await _run(controller, 'selector_probe');
    expect(hidden.data['visible'], isFalse);

    await _loadFixture(controller, 'nro_oc_reverted.html');
    final rejected = await _run(
      controller,
      'nro_oc',
      payload: _nroPayload('apply'),
    );
    expect(rejected.code, 'CONTROLLED_INPUT_REJECTED');

    await _loadFixture(controller, 'nro_oc_aria_invalid.html');
    expect(
      (await _run(controller, 'nro_oc', payload: _nroPayload('apply'))).code,
      'NRO_OC_APPLIED',
    );
    expect(
      (await _pollVerification(controller)).code,
      'FIELD_VALIDATION_ERROR',
    );

    await _loadFixture(controller, 'iframe_same_origin_v5.html');
    final iframe = await _run(controller, 'selector_probe');
    expect(iframe.data['insideIframe'], isTrue);

    await _loadFixture(controller, 'shadow_dom_open.html');
    final shadow = await _run(controller, 'selector_probe');
    expect(shadow.data['insideShadowDom'], isTrue);

    await _loadFixture(controller, 'shadow_dom_closed.html');
    expect(
      (await _run(controller, 'selector_probe')).code,
      'NRO_OC_CLOSED_SHADOW_ROOT',
    );
  });
}

Future<void> _loadFixture(WebViewController controller, String name) async {
  final html = await rootBundle.loadString('test/fixtures/webview/$name');
  await controller.loadHtmlString(
    html,
    baseUrl: 'https://fixture.example.test/$name',
  );
  await controller.runJavaScriptReturningResult('document.readyState');
}

Future<JavascriptResult> _run(
  WebViewController controller,
  String scriptName, {
  Map<String, Object?>? payload,
}) async {
  final common = await rootBundle.loadString('assets/automation/common.js');
  final script = await rootBundle.loadString(
    'assets/automation/$scriptName.js',
  );
  final selector = SelectorRegistry.byKey('purchaseOrderNumber');
  final input =
      payload ??
      {
        'logicalKey': selector.key,
        'alternatives': selector.alternatives,
        'version': selector.version,
      };
  final source =
      '''(() => {
    $common
    const payload = ${JavascriptPayloadEncoder.encode(input)};
    return JSON.stringify($script);
  })()''';
  return JavascriptResult.fromPlatformValue(
    await controller.runJavaScriptReturningResult(source),
  );
}

Map<String, Object?> _nroPayload(String action) {
  final selector = SelectorRegistry.byKey('purchaseOrderNumber');
  return {
    'action': action,
    'logicalKey': selector.key,
    'alternatives': selector.alternatives,
    'version': AppConfig.selectorVersion,
    'value': 'FIXTURE-0001',
    'domStableMs': 100,
    'secondPersistenceMs': 100,
    'controlledFramework': true,
  };
}

Future<JavascriptResult> _pollVerification(WebViewController controller) async {
  final started = DateTime.now();
  while (true) {
    final result = await _run(
      controller,
      'nro_oc',
      payload: _nroPayload('verify'),
    );
    if (result.success || !result.retryable) return result;
    if (DateTime.now().difference(started) > const Duration(seconds: 3)) {
      return result;
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}
