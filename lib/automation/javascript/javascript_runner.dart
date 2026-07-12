import '../../core/security/webview_security_policy.dart';
import '../engine/automation_exception.dart';
import '../webview/automy_web_controller.dart';
import 'javascript_payload_encoder.dart';
import 'javascript_result.dart';
import 'script_repository.dart';

final class JavascriptRunner {
  JavascriptRunner({
    required AutomyWebController webController,
    required WebViewSecurityPolicy Function() policyReader,
    ScriptRepository? scripts,
  }) : this._(webController, policyReader, scripts ?? ScriptRepository());

  JavascriptRunner._(this._webController, this._policyReader, this._scripts);

  final AutomyWebController _webController;
  final WebViewSecurityPolicy Function() _policyReader;
  final ScriptRepository _scripts;

  Future<JavascriptResult> run(
    String scriptName, {
    Map<String, Object?> payload = const {},
  }) async {
    final policy = _policyReader();
    final uri = _webController.currentUri;
    if (!policy.canRunJavaScript(uri)) {
      throw const AutomationException(
        'JavaScript bloqueado fuera de un dominio autorizado.',
        code: 'UNAUTHORIZED_SCRIPT_ORIGIN',
      );
    }
    final common = await _scripts.load('common');
    final script = await _scripts.load(scriptName);
    final encodedPayload = JavascriptPayloadEncoder.encode(payload);
    final source =
        '''(() => {
      $common
      const payload = $encodedPayload;
      return JSON.stringify($script);
    })()''';
    final value = await _webController.controller.runJavaScriptReturningResult(
      source,
    );
    return JavascriptResult.fromPlatformValue(value);
  }
}
