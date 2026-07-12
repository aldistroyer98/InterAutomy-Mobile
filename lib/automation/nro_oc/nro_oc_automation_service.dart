import '../../app/app_config.dart';
import '../diagnostics/diagnostic_models.dart';
import '../engine/automation_exception.dart';
import '../javascript/javascript_result.dart';
import '../javascript/javascript_runner.dart';
import '../selectors/selector_registry.dart';
import '../waiting/wait_manager.dart';

final class NroOcAutomationResult {
  const NroOcAutomationResult({
    required this.success,
    required this.code,
    required this.message,
    required this.probe,
  });

  final bool success;
  final String code;
  final String message;
  final SelectorProbeResult probe;
}

final class NroOcAutomationService {
  NroOcAutomationService(this._runner, this._waitManager);

  final JavascriptRunner _runner;
  final WaitManager _waitManager;

  Future<SelectorProbeResult> probe({
    required bool Function() isCancelled,
    Duration timeout = AppConfig.selectorTimeout,
  }) async {
    final stopwatch = Stopwatch()..start();
    var attempts = 0;
    final definition = SelectorRegistry.byKey('purchaseOrderNumber');
    try {
      final result = await _waitManager.until(
        probe: () async {
          attempts += 1;
          return _runner.run(
            'selector_probe',
            payload: {
              'logicalKey': definition.key,
              'alternatives': definition.alternatives,
              'version': definition.version,
            },
          );
        },
        matches: (value) =>
            (value.success &&
                value.data['visible'] == true &&
                value.data['enabled'] == true) ||
            (!value.success && !value.retryable),
        timeout: timeout,
        isCancelled: isCancelled,
        timeoutMessage:
            'No se encontró el campo NRO OC dentro del tiempo permitido.',
      );
      return _probeFrom(result, stopwatch.elapsedMilliseconds, attempts - 1);
    } on AutomationException catch (error) {
      return SelectorProbeResult(
        code: error.code,
        elapsedMilliseconds: stopwatch.elapsedMilliseconds,
        retries: attempts > 0 ? attempts - 1 : 0,
      );
    }
  }

  Future<NroOcAutomationResult> applyAndVerify({
    required String value,
    required String framework,
    required bool Function() isCancelled,
  }) async {
    final definition = SelectorRegistry.byKey('purchaseOrderNumber');
    final stopwatch = Stopwatch()..start();
    var attempts = 0;
    final payload = <String, Object?>{
      'logicalKey': definition.key,
      'alternatives': definition.alternatives,
      'version': definition.version,
      'value': value,
      'persistenceMs': 600,
      'domStableMs': 350,
      'secondPersistenceMs': 500,
      'controlledFramework': const {
        'react',
        'angular',
        'vue',
        'nextjs',
      }.contains(framework),
    };
    final applied = await _runner.run(
      'nro_oc',
      payload: {...payload, 'action': 'apply'},
    );
    if (!applied.success) {
      return NroOcAutomationResult(
        success: false,
        code: applied.code,
        message: applied.message,
        probe: _probeFrom(applied, stopwatch.elapsedMilliseconds, 0),
      );
    }
    try {
      final verified = await _waitManager.until(
        probe: () async {
          attempts += 1;
          return _runner.run(
            'nro_oc',
            payload: {...payload, 'action': 'verify'},
          );
        },
        matches: (result) => result.success || !result.retryable,
        timeout: AppConfig.valuePersistenceTimeout,
        isCancelled: isCancelled,
        timeoutMessage: 'No se pudo confirmar la persistencia de NRO OC.',
      );
      return NroOcAutomationResult(
        success: verified.success,
        code: verified.code,
        message: verified.message,
        probe: _probeFrom(
          verified,
          stopwatch.elapsedMilliseconds,
          attempts - 1,
        ),
      );
    } on AutomationException catch (error) {
      return NroOcAutomationResult(
        success: false,
        code: error.code,
        message: error.message,
        probe: SelectorProbeResult(
          code: error.code,
          elapsedMilliseconds: stopwatch.elapsedMilliseconds,
          retries: attempts > 0 ? attempts - 1 : 0,
        ),
      );
    }
  }

  Future<NroOcAutomationResult> verify({
    required String value,
    required String framework,
    required bool Function() isCancelled,
  }) async {
    final definition = SelectorRegistry.byKey('purchaseOrderNumber');
    final stopwatch = Stopwatch()..start();
    var attempts = 0;
    final payload = <String, Object?>{
      'action': 'verify',
      'logicalKey': definition.key,
      'alternatives': definition.alternatives,
      'version': definition.version,
      'value': value,
      'persistenceMs': 0,
      'domStableMs': 350,
      'secondPersistenceMs': 500,
      'controlledFramework': const {
        'react',
        'angular',
        'vue',
        'nextjs',
      }.contains(framework),
    };
    try {
      final result = await _waitManager.until(
        probe: () async {
          attempts += 1;
          return _runner.run('nro_oc', payload: payload);
        },
        matches: (result) => result.success || !result.retryable,
        timeout: AppConfig.valuePersistenceTimeout,
        isCancelled: isCancelled,
        timeoutMessage: 'No se confirmó la segunda persistencia de NRO OC.',
      );
      return NroOcAutomationResult(
        success: result.success,
        code: result.code,
        message: result.message,
        probe: _probeFrom(result, stopwatch.elapsedMilliseconds, attempts - 1),
      );
    } on AutomationException catch (error) {
      return NroOcAutomationResult(
        success: false,
        code: error.code,
        message: error.message,
        probe: SelectorProbeResult(
          code: error.code,
          elapsedMilliseconds: stopwatch.elapsedMilliseconds,
          retries: attempts > 0 ? attempts - 1 : 0,
        ),
      );
    }
  }

  Future<NroOcAutomationResult> clear() => _operate('clear');

  Future<NroOcAutomationResult> _operate(
    String action, {
    String value = '',
    String framework = 'unknown',
  }) async {
    final definition = SelectorRegistry.byKey('purchaseOrderNumber');
    final stopwatch = Stopwatch()..start();
    final result = await _runner.run(
      'nro_oc',
      payload: {
        'action': action,
        'logicalKey': definition.key,
        'alternatives': definition.alternatives,
        'version': definition.version,
        'value': value,
        'persistenceMs': 0,
        'controlledFramework': const {
          'react',
          'angular',
          'vue',
          'nextjs',
        }.contains(framework),
      },
    );
    return NroOcAutomationResult(
      success: result.success,
      code: result.code,
      message: result.message,
      probe: _probeFrom(result, stopwatch.elapsedMilliseconds, 0),
    );
  }

  static SelectorProbeResult _probeFrom(
    JavascriptResult result,
    int elapsed,
    int retries,
  ) => SelectorProbeResult(
    success: result.success,
    code: result.code,
    logicalKey: result.data['logicalKey']?.toString() ?? 'purchaseOrderNumber',
    alternativeIndex: result.data['alternativeIndex'] is num
        ? (result.data['alternativeIndex'] as num).toInt()
        : null,
    visible: result.data['visible'] == true || result.success,
    enabled: result.data['enabled'] == true || result.success,
    elapsedMilliseconds: elapsed,
    retries: retries < 0 ? 0 : retries,
    elementType: result.data['elementType']?.toString() ?? '',
    tag: result.data['tag']?.toString() ?? '',
    sameOrigin: result.data['sameOrigin'] != false,
    insideShadowDom: result.data['insideShadowDom'] == true,
    insideIframe: result.data['insideIframe'] == true,
    alternatives: result.data['alternatives'] is List
        ? List.unmodifiable(
            (result.data['alternatives'] as List).whereType<Map>().map(
              (item) => SelectorAlternativeProbe.fromJson(
                item.map((key, value) => MapEntry(key.toString(), value)),
              ),
            ),
          )
        : const [],
    validationError:
        result.code == 'FIELD_VALIDATION_ERROR' ||
        result.data['validationError'] == true,
    validationSignal: result.data['validationSignal']?.toString() ?? '',
    version: AppConfig.selectorVersion,
  );
}
