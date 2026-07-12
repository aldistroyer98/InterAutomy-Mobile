import 'package:flutter_test/flutter_test.dart';
import 'package:interautomy_mobile/automation/engine/automation_exception.dart';
import 'package:interautomy_mobile/automation/javascript/javascript_result.dart';
import 'package:interautomy_mobile/automation/logging/automation_log_sanitizer.dart';
import 'package:interautomy_mobile/automation/selectors/selector_registry.dart';
import 'package:interautomy_mobile/automation/state/automation_state.dart';
import 'package:interautomy_mobile/automation/state/automation_state_machine.dart';
import 'package:interautomy_mobile/automation/waiting/retry_policy.dart';
import 'package:interautomy_mobile/core/security/webview_security_policy.dart';

void main() {
  group('WebViewSecurityPolicy', () {
    final policy = WebViewSecurityPolicy(
      portalUrl: WebViewSecurityPolicy.parsePortalUrl(
        'https://automy.example.test/inicio?token=no-mostrar',
      ),
      additionalHosts: const ['login.example.test'],
    );

    test('solo permite HTTPS y hosts explícitos', () {
      expect(
        policy.isAllowedUri(Uri.parse('https://automy.example.test/form')),
        isTrue,
      );
      expect(
        policy.isAllowedUri(Uri.parse('https://login.example.test/sso')),
        isTrue,
      );
      expect(
        policy.isAllowedUri(Uri.parse('http://automy.example.test/form')),
        isFalse,
      );
      expect(
        policy.isAllowedUri(Uri.parse('https://otro.example.test/form')),
        isFalse,
      );
    });

    test('rechaza configuración insegura', () {
      expect(
        WebViewSecurityPolicy.parsePortalUrl('http://automy.example.test'),
        isNull,
      );
      expect(
        WebViewSecurityPolicy.parsePortalUrl(
          'https://user:pass@automy.example.test',
        ),
        isNull,
      );
      expect(
        WebViewSecurityPolicy.parseAdditionalHosts('login.example.test,/ruta'),
        isNull,
      );
    });

    test('oculta query y fragment al mostrar URL', () {
      expect(
        WebViewSecurityPolicy.displayUrl(
          Uri.parse('https://automy.example.test/a?secret=1#x'),
        ),
        'https://automy.example.test/a',
      );
    });
  });

  group('AutomationStateMachine', () {
    test('acepta el recorrido inicial y conserva metadatos de transición', () {
      final machine = AutomationStateMachine();
      final change = machine.transitionTo(
        AutomationState.openingPortal,
        message: 'Abriendo Automy',
        progress: .1,
      );
      expect(change.previous, AutomationState.idle);
      expect(change.current, AutomationState.openingPortal);
      expect(change.progress, .1);
    });

    test('rechaza una transición inválida', () {
      final machine = AutomationStateMachine();
      expect(
        () => machine.transitionTo(
          AutomationState.completed,
          message: 'No permitido',
          progress: 1,
        ),
        throwsA(isA<AutomationException>()),
      );
    });
  });

  test('retry policy aplica espera progresiva', () {
    const retry = RetryPolicy(
      maxAttempts: 3,
      initialDelay: Duration(milliseconds: 100),
      backoffFactor: 2,
    );
    expect(retry.delayForAttempt(0), const Duration(milliseconds: 100));
    expect(retry.delayForAttempt(2), const Duration(milliseconds: 400));
  });

  test('selector registry conserva claves lógicas y alternativas', () {
    final field = SelectorRegistry.byKey('orderNumber');
    expect(field.required, isTrue);
    expect(field.alternatives, contains('#form_field_groups_nro_oc'));
  });

  test('resultado JavaScript decodifica JSON serializable', () {
    final result = JavascriptResult.fromPlatformValue(
      '{"success":true,"code":"FIELD_UPDATED","message":"Campo actualizado","data":{"selectorKey":"orderNumber"}}',
    );
    expect(result.success, isTrue);
    expect(result.data['selectorKey'], 'orderNumber');
  });

  test('bitácora oculta secretos conocidos', () {
    final output = AutomationLogSanitizer.sanitize(
      'token=abc123 password=secreto Authorization: Bearer jwt.valor',
    );
    expect(output, isNot(contains('abc123')));
    expect(output, isNot(contains('secreto')));
    expect(output, isNot(contains('jwt.valor')));
  });
}
