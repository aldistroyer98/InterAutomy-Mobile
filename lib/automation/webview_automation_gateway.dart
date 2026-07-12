import 'package:flutter/foundation.dart';

import '../core/security/webview_security_policy.dart';
import '../domain/entities/execution.dart';
import '../domain/entities/order.dart';
import '../domain/services/automation_gateway.dart';
import 'detection/page_detector.dart';
import 'engine/automation_context.dart';
import 'engine/automation_exception.dart';
import 'javascript/javascript_runner.dart';
import 'logging/automation_log_sanitizer.dart';
import 'selectors/selector_registry.dart';
import 'state/automation_state.dart';
import 'state/automation_state_machine.dart';
import 'upload/file_picker_service.dart';
import 'waiting/wait_manager.dart';
import 'webview/automy_web_controller.dart';
import 'webview/portal_diagnostics.dart';
import 'webview/webview_session_service.dart';

/// Implementación autónoma: Dart gobierna el flujo y JavaScript solo modifica
/// el DOM del origen HTTPS autorizado. Nunca envía credenciales ni confirma el
/// último envío sin acción manual.
final class WebViewAutomationGateway implements AutomationGateway {
  WebViewAutomationGateway({
    required WebViewSecurityPolicyReader policyReader,
    AutomyWebController? webController,
    WaitManager? waitManager,
    FilePickerService? filePicker,
  }) : this._(
         policyReader,
         webController ?? AutomyWebController(),
         waitManager ?? const WaitManager(),
         filePicker ?? FilePickerService(),
       );

  WebViewAutomationGateway._(
    this._policyReader,
    this.webController,
    this._waitManager,
    this._filePicker,
  ) {
    _javascript = JavascriptRunner(
      webController: webController,
      policyReader: _policyReader,
    );
    _pageDetector = PageDetector(_javascript);
    _sessionService = WebViewSessionService(webController);
  }

  final WebViewSecurityPolicyReader _policyReader;
  final AutomyWebController webController;
  final WaitManager _waitManager;
  final FilePickerService _filePicker;
  late final JavascriptRunner _javascript;
  late final PageDetector _pageDetector;
  late final WebViewSessionService _sessionService;
  final Map<String, _ActiveExecution> _active = {};

  ValueNotifier<PortalDiagnostics> get diagnostics => webController.diagnostics;

  Future<void> openConfiguredPortal() =>
      webController.openPortal(_policyReader());

  Future<PortalDiagnostics> refreshDiagnostics() async {
    final inspection = await _pageDetector.inspect(
      webController.diagnostics.value,
    );
    webController.updateDiagnostics(inspection);
    return inspection;
  }

  Future<void> clearSession() => _sessionService.clearSession();

  Future<List<String>> pickFilesForWeb(dynamic params) =>
      _filePicker.pickForWeb(params);

  @override
  Stream<Execution> execute(Order order) async* {
    final context = AutomationContext(
      executionId: order.id,
      order: order,
      createdAt: DateTime.now(),
    );
    final active = _ActiveExecution(
      context,
      _newExecution(order, context.createdAt),
    );
    _active[order.id] = active;
    try {
      if (!_policyReader().isConfigured) {
        yield _fail(
          active,
          'PORTAL_URL_REQUIRED',
          'Configura la URL HTTPS de Automy antes de ejecutar.',
        );
        return;
      }
      if (!webController.isBound) {
        yield _fail(
          active,
          'WEBVIEW_NOT_READY',
          'Abre el navegador integrado antes de preparar el pedido.',
        );
        return;
      }

      yield _transition(
        active,
        AutomationState.openingPortal,
        'Abriendo Automy en el navegador integrado.',
        .05,
      );
      final current = webController.currentUri;
      if (current == null || !_policyReader().isAllowedUri(current)) {
        await openConfiguredPortal();
      }

      yield _transition(
        active,
        AutomationState.waitingForPage,
        'Esperando que Automy termine de cargar.',
        .12,
      );
      await _waitForKnownPage(active, const Duration(seconds: 45));

      yield _transition(
        active,
        AutomationState.detectingSession,
        'Comprobando la sesión de Automy.',
        .2,
      );
      var diagnostics = await refreshDiagnostics();
      if (diagnostics.page == PortalPage.login ||
          diagnostics.page == PortalPage.sessionExpired) {
        yield _transition(
          active,
          AutomationState.waitingForLogin,
          'Inicia sesión manualmente en Automy para continuar.',
          .25,
        );
        diagnostics = await _waitManager.until(
          probe: refreshDiagnostics,
          matches: (value) =>
              value.page != PortalPage.login &&
              value.page != PortalPage.sessionExpired,
          timeout: const Duration(minutes: 15),
          isCancelled: () => context.cancelled,
          timeoutMessage: 'No se detectó una sesión iniciada en Automy.',
        );
        yield _transition(
          active,
          AutomationState.detectingSession,
          'Sesión manual detectada.',
          .3,
        );
      }

      if (diagnostics.page != PortalPage.clientForm) {
        yield _fail(
          active,
          'UNEXPECTED_PAGE',
          'Navega manualmente al formulario del pedido antes de automatizar el campo inicial.',
        );
        return;
      }
      final orderNumber = order.client.nroOc.trim();
      if (orderNumber.isEmpty) {
        yield _fail(
          active,
          'ORDER_NUMBER_REQUIRED',
          'El NRO OC es necesario para la prueba de campo inicial.',
        );
        return;
      }

      yield _transition(
        active,
        AutomationState.navigating,
        'Formulario de pedido reconocido.',
        .38,
      );
      yield _transition(
        active,
        AutomationState.fillingClient,
        'Completando y verificando NRO OC.',
        .5,
      );
      final selector = SelectorRegistry.byKey('orderNumber');
      context.lastSelector = selector.key;
      final result = await _javascript.run(
        'client',
        payload: {
          'selectorKey': selector.key,
          'alternatives': selector.alternatives,
          'value': orderNumber,
        },
      );
      if (!result.success) {
        yield _fail(active, result.code, result.message);
        return;
      }

      yield _transition(
        active,
        AutomationState.validating,
        'NRO OC fue verificado en el DOM.',
        .65,
      );
      yield _transition(
        active,
        AutomationState.waitingForManualReview,
        'Revise toda la información con paciencia y detalle.',
        .8,
      );

      final resultState = await _waitManager.until(
        probe: () => _javascript.run('result'),
        matches: (value) => value.data['result']?.toString() != 'unknown',
        timeout: const Duration(minutes: 20),
        isCancelled: () => context.cancelled,
        timeoutMessage: 'Resultado no confirmado; revise Automy manualmente.',
      );
      yield _transition(
        active,
        AutomationState.detectingResult,
        'Comprobando la respuesta de Automy.',
        .92,
      );
      if (resultState.data['result'] == 'success') {
        yield _transition(
          active,
          AutomationState.completed,
          'Producto enviado.',
          1,
        );
      } else {
        yield _fail(active, 'PORTAL_RESULT_ERROR', resultState.message);
      }
    } on AutomationException catch (error) {
      if (error.code == 'CANCELLED') {
        yield _cancel(active);
      } else {
        yield _fail(active, error.code, error.message);
      }
    } catch (error) {
      yield _fail(
        active,
        'UNEXPECTED_ERROR',
        'La automatización se detuvo: $error',
      );
    } finally {
      _active.remove(order.id);
    }
  }

  @override
  Future<Execution> confirmBrowserClosed(String executionId) async {
    final active = _active[executionId];
    if (active == null) {
      throw StateError('No existe una ejecución WebView activa.');
    }
    if (active.machine.current != AutomationState.waitingForManualReview) {
      return active.execution;
    }
    final result = await _javascript.run('result');
    if (result.data['result'] == 'success') return active.execution;
    active.execution = active.execution.copyWith(
      updatedAt: DateTime.now(),
      mensajeError: 'Resultado no confirmado. Continúe la revisión en Automy.',
      bitacora: [
        ...active.execution.bitacora,
        _log(ExecutionStatus.waitingForReview, 'Resultado no confirmado.'),
      ],
    );
    return active.execution;
  }

  @override
  Future<void> cancel(String executionId) async {
    final active = _active[executionId];
    if (active != null) active.context.cancelled = true;
  }

  Future<void> _waitForKnownPage(
    _ActiveExecution active,
    Duration timeout,
  ) async {
    await _waitManager.until(
      probe: refreshDiagnostics,
      matches: (value) =>
          value.page != PortalPage.unknown || value.loadingProgress == 100,
      timeout: timeout,
      isCancelled: () => active.context.cancelled,
    );
  }

  Execution _transition(
    _ActiveExecution active,
    AutomationState next,
    String message,
    double progress,
  ) {
    final stateChange = active.machine.transitionTo(
      next,
      message: message,
      progress: progress,
    );
    active.context.state = next;
    final status = _executionStatus(next);
    active.execution = active.execution.copyWith(
      updatedAt: stateChange.timestamp,
      estado: status,
      progreso: progress,
      clearError: true,
      bitacora: [...active.execution.bitacora, _log(status, message)],
    );
    return active.execution;
  }

  Execution _fail(_ActiveExecution active, String code, String message) {
    final sanitized = AutomationLogSanitizer.sanitize(message);
    if (!active.machine.current.isTerminal) {
      active.machine.transitionTo(
        AutomationState.failed,
        message: sanitized,
        progress: active.execution.progreso,
        error: code,
      );
    }
    active.context.state = AutomationState.failed;
    active.execution = active.execution.copyWith(
      updatedAt: DateTime.now(),
      estado: ExecutionStatus.failed,
      mensajeError: sanitized,
      bitacora: [
        ...active.execution.bitacora,
        _log(ExecutionStatus.failed, sanitized),
      ],
    );
    return active.execution;
  }

  Execution _cancel(_ActiveExecution active) {
    if (!active.machine.current.isTerminal) {
      _transition(
        active,
        AutomationState.cancelling,
        'Cancelando ejecución.',
        active.execution.progreso,
      );
      _transition(
        active,
        AutomationState.cancelled,
        'Ejecución cancelada.',
        active.execution.progreso,
      );
    }
    return active.execution;
  }

  static ExecutionStatus _executionStatus(AutomationState state) =>
      switch (state) {
        AutomationState.waitingForManualReview =>
          ExecutionStatus.waitingForReview,
        AutomationState.completed => ExecutionStatus.completed,
        AutomationState.failed => ExecutionStatus.failed,
        AutomationState.cancelled => ExecutionStatus.cancelled,
        AutomationState.detectingSession ||
        AutomationState.validating => ExecutionStatus.validating,
        AutomationState.fillingClient ||
        AutomationState.fillingConditions ||
        AutomationState.fillingProducts ||
        AutomationState.uploadingFiles ||
        AutomationState.detectingResult => ExecutionStatus.fillingInformation,
        AutomationState.idle => ExecutionStatus.pending,
        _ => ExecutionStatus.startingBrowser,
      };

  static Execution _newExecution(Order order, DateTime now) => Execution(
    id: order.id,
    cliente: order.client,
    productos: List.unmodifiable(order.products),
    lineas: order.lines,
    createdAt: now,
    updatedAt: now,
    estado: ExecutionStatus.pending,
    progreso: 0,
    bitacora: const [],
  );

  static ExecutionLogEntry _log(ExecutionStatus status, String message) =>
      ExecutionLogEntry(
        timestamp: DateTime.now(),
        message: AutomationLogSanitizer.sanitize(message),
        status: status,
      );

  void dispose() => webController.dispose();
}

typedef WebViewSecurityPolicyReader = WebViewSecurityPolicy Function();

final class _ActiveExecution {
  _ActiveExecution(this.context, this.execution);

  final AutomationContext context;
  final AutomationStateMachine machine = AutomationStateMachine();
  Execution execution;
}
