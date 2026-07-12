import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:interautomy_mobile/app/app_config.dart';
import 'package:interautomy_mobile/automation/detection/page_detector.dart';
import 'package:interautomy_mobile/automation/detection/result_text_detector.dart';
import 'package:interautomy_mobile/automation/diagnostics/diagnostic_models.dart';
import 'package:interautomy_mobile/automation/diagnostics/portal_fingerprint_builder.dart';
import 'package:interautomy_mobile/automation/engine/automation_exception.dart';
import 'package:interautomy_mobile/automation/javascript/javascript_payload_encoder.dart';
import 'package:interautomy_mobile/automation/logging/automation_log_sanitizer.dart';
import 'package:interautomy_mobile/automation/selectors/selector_registry.dart';
import 'package:interautomy_mobile/automation/waiting/retry_policy.dart';
import 'package:interautomy_mobile/automation/waiting/wait_manager.dart';

void main() {
  test('WebDiagnosticSnapshot serializa solo el resumen permitido', () {
    final snapshot = WebDiagnosticSnapshot(
      timestamp: DateTime.utc(2026, 7, 12),
      sanitizedUrl: 'https://portal.example.test/form',
      host: 'portal.example.test',
      title: 'Formulario',
      loadingState: 'ready',
      detectedPage: 'clientForm',
      framework: const FrameworkDetectionResult(
        name: 'react',
        confidence: .9,
        signals: ['react-root-attribute'],
      ),
      structure: const PageStructureSummary(inputs: 2, buttons: 1),
      frames: const FrameSummary(),
      shadowDom: const ShadowDomSummary(),
      storage: const StorageAvailability(
        sessionStorage: true,
        localStorage: true,
        cookies: true,
      ),
      popup: const PopupDetectionResult(),
      fingerprint: const PortalFingerprint(value: 'a1b2c3d4', recognized: true),
    );
    final json = snapshot.toJson();
    expect(json['host'], 'portal.example.test');
    expect(json.toString(), isNot(contains('cookie=')));
    expect(json.toString(), isNot(contains('password')));
    expect(json.toString(), isNot(contains('<html')));
  });

  test('fingerprint es reproducible, normaliza ids y reconoce NRO OC', () {
    final first = PortalFingerprintBuilder.build(
      host: 'PORTAL.EXAMPLE.TEST',
      path: '/orders/12345',
      title: '  Formulario   OC ',
      selectorKeys: const ['purchaseOrderNumber'],
      controlCount: 8,
      framework: 'React',
    );
    final second = PortalFingerprintBuilder.build(
      host: 'portal.example.test',
      path: '/orders/99999',
      title: 'formulario oc',
      selectorKeys: const ['purchaseOrderNumber'],
      controlCount: 10,
      framework: 'react',
    );
    expect(first.value, second.value);
    expect(first.recognized, isTrue);
  });

  test('modelos resumen framework iframe y Shadow DOM', () {
    final framework = FrameworkDetectionResult.fromJson({
      'name': 'angular',
      'confidence': .95,
      'signals': ['ng-version'],
    });
    final frames = FrameSummary.fromJson({
      'frames': [
        {'origin': 'sameOrigin', 'visible': true},
        {'origin': 'crossOrigin', 'source': 'https://sso.example.test/'},
      ],
      'nroOcCrossOrigin': true,
    });
    final shadow = ShadowDomSummary.fromJson({
      'count': 2,
      'hosts': ['nro-oc-field'],
      'maxDepth': 2,
      'inputCount': 1,
      'possibleNroOc': true,
    });
    expect(framework.name, 'angular');
    expect(frames.crossOrigin, 1);
    expect(frames.nroOcCrossOrigin, isTrue);
    expect(shadow.possibleNroOc, isTrue);
  });

  group('PageDetector', () {
    PortalPage detect(
      List<String> signals, {
      bool blocked = false,
      bool recognized = true,
    }) => PageDetector.detect(
      url: Uri.parse('https://portal.example.test/process'),
      title: 'Portal',
      signals: signals,
      blockedBySecurity: blocked,
      fingerprintRecognized: recognized,
    );

    test('prioriza seguridad y sesión expirada', () {
      expect(detect(['success'], blocked: true), PortalPage.blockedBySecurity);
      expect(detect(['sessionExpired', 'success']), PortalPage.sessionExpired);
    });

    test('review tiene prioridad sobre clientForm', () {
      expect(detect(['clientForm', 'review']), PortalPage.review);
    });

    test('estructura desconocida detiene clientForm', () {
      expect(
        detect(['clientForm'], recognized: false),
        PortalPage.unsupportedStructure,
      );
    });
  });

  test(
    'selector registry ordena alternativas estables y no expone otro campo',
    () {
      final field = SelectorRegistry.byKey('purchaseOrderNumber');
      expect(field.alternatives.first, '[data-testid="nro-oc"]');
      expect(field.alternatives[1], '[data-field="nro_oc"]');
      expect(field.alternatives.last, '.nro-oc input');
      expect(SelectorRegistry.definitions, hasLength(1));
    },
  );

  test('payload NRO OC conserva valor como JSON sin interpolar JavaScript', () {
    final encoded = JavascriptPayloadEncoder.encode({
      'value': 'OC"; window.bad = true; //',
      'logicalKey': 'purchaseOrderNumber',
    });
    expect(encoded, contains(r'\"'));
    expect(encoded, contains('purchaseOrderNumber'));
  });

  test(
    'sanitización oculta secretos, correo y NRO OC; máscara deja cuatro',
    () {
      final sanitized = AutomationLogSanitizer.sanitize(
        'token=abc cookie=xyz correo demo@example.test NRO OC: ABCD-123456',
      );
      expect(sanitized, isNot(contains('abc')));
      expect(sanitized, isNot(contains('xyz')));
      expect(sanitized, isNot(contains('demo@example.test')));
      expect(sanitized, isNot(contains('ABCD-123456')));
      expect(AutomationLogSanitizer.maskValue('ABCD-123456'), '****3456');
    },
  );

  test('resultado reconoce success error y unknown', () {
    expect(
      ResultTextDetector.detect('Solicitud enviada'),
      PortalResult.success,
    );
    expect(
      ResultTextDetector.detect('Pedido registrado'),
      PortalResult.success,
    );
    expect(ResultTextDetector.detect('Producto enviado'), PortalResult.success);
    expect(ResultTextDetector.detect('Error al procesar'), PortalResult.error);
    expect(
      ResultTextDetector.detect('Texto irrelevante'),
      PortalResult.unknown,
    );
    expect(
      ResultTextDetector.detect('Resultado desconocido'),
      PortalResult.unknown,
    );
  });

  test('retry policy distingue condiciones recuperables y definitivas', () {
    const policy = RetryPolicy();
    expect(policy.shouldRetry(RetryReason.selectorPending), isTrue);
    expect(policy.shouldRetry(RetryReason.domChanging), isTrue);
    expect(policy.shouldRetry(RetryReason.domainBlocked), isFalse);
    expect(policy.shouldRetry(RetryReason.crossOriginFrame), isFalse);
    expect(policy.shouldRetry(RetryReason.sessionExpired), isFalse);
  });

  test('WaitManager respeta timeout y cancelación', () async {
    const wait = WaitManager(pollInterval: Duration(milliseconds: 1));
    await expectLater(
      wait.until(
        probe: () async => false,
        matches: (value) => value,
        timeout: const Duration(milliseconds: 3),
        isCancelled: () => false,
      ),
      throwsA(
        isA<AutomationException>().having(
          (error) => error.code,
          'code',
          'WAIT_TIMEOUT',
        ),
      ),
    );
    await expectLater(
      wait.until(
        probe: () async => false,
        matches: (value) => value,
        timeout: const Duration(seconds: 1),
        isCancelled: () => true,
      ),
      throwsA(
        isA<AutomationException>().having(
          (error) => error.code,
          'code',
          'CANCELLED',
        ),
      ),
    );
  });

  test('scripts locales son versionados y no usan evaluación dinámica', () {
    const names = [
      'common',
      'diagnostics',
      'framework_detection',
      'iframe_detection',
      'shadow_dom_detection',
      'selector_probe',
      'nro_oc',
      'result',
    ];
    for (final name in names) {
      final source = File('assets/automation/$name.js').readAsStringSync();
      expect(source, isNot(contains('eval(')), reason: name);
      expect(source, isNot(contains('new Function')), reason: name);
      expect(source, isNot(contains('fetch(')), reason: name);
    }
    final nro = File('assets/automation/nro_oc.js').readAsStringSync();
    expect(nro, contains('setNativeValue'));
    expect(nro, contains('actualMatches'));
    expect(AppConfig.allowAutomaticSubmission, isFalse);
  });

  test('fixtures HTML requeridos existen y no contienen datos reales', () {
    const names = [
      'login',
      'client_form',
      'react_controlled_input',
      'angular_like_input',
      'iframe_same_origin',
      'iframe_cross_origin',
      'shadow_dom_open',
      'result_success',
      'result_error',
      'result_unknown',
    ];
    for (final name in names) {
      final file = File('test/fixtures/webview/$name.html');
      expect(file.existsSync(), isTrue, reason: name);
      expect(file.readAsStringSync(), isNot(contains('automy.pe')));
    }
  });
}
