import '../../domain/entities/execution.dart';
import '../../domain/entities/order.dart';
import '../../domain/services/automation_gateway.dart';

final class DemoAutomationGateway implements AutomationGateway {
  DemoAutomationGateway({
    this.stepDuration = const Duration(milliseconds: 350),
  });

  final Duration stepDuration;
  final Map<String, Execution> _executions = {};
  final Set<String> _cancelled = {};

  static const _steps = <(ExecutionStatus, double, String)>[
    (ExecutionStatus.pending, 0.05, 'Ejecución creada.'),
    (ExecutionStatus.validating, 0.15, 'Validando cliente y productos.'),
    (ExecutionStatus.queued, 0.28, 'Ejecución agregada a la cola demo.'),
    (ExecutionStatus.startingAgent, 0.42, 'Iniciando agente Windows simulado.'),
    (ExecutionStatus.startingBrowser, 0.57, 'Iniciando navegador simulado.'),
    (
      ExecutionStatus.fillingInformation,
      0.75,
      'Completando información del pedido.',
    ),
    (ExecutionStatus.waitingForReview, 0.9, 'Formulario listo para revisión.'),
  ];

  @override
  Stream<Execution> execute(Order order) async* {
    final createdAt = DateTime.now();
    var logs = <ExecutionLogEntry>[];
    for (final (status, progress, message) in _steps) {
      if (_cancelled.contains(order.id)) {
        final cancelled = _create(
          order,
          createdAt,
          ExecutionStatus.cancelled,
          progress,
          [...logs, _log(ExecutionStatus.cancelled, 'Ejecución cancelada.')],
        );
        _executions[order.id] = cancelled;
        yield cancelled;
        return;
      }
      await Future<void>.delayed(stepDuration);
      logs = [...logs, _log(status, message)];
      final execution = _create(order, createdAt, status, progress, logs);
      _executions[order.id] = execution;
      yield execution;
    }
  }

  @override
  Future<Execution> confirmBrowserClosed(String executionId) async {
    final current = _executions[executionId];
    if (current == null || current.estado != ExecutionStatus.waitingForReview) {
      throw StateError('La ejecución no está esperando revisión.');
    }
    await Future<void>.delayed(stepDuration);
    final completed = current.copyWith(
      updatedAt: DateTime.now(),
      estado: ExecutionStatus.completed,
      progreso: 1,
      bitacora: [
        ...current.bitacora,
        _log(ExecutionStatus.completed, 'Producto enviado.'),
      ],
    );
    _executions[executionId] = completed;
    return completed;
  }

  @override
  Future<void> cancel(String executionId) async => _cancelled.add(executionId);

  Execution _create(
    Order order,
    DateTime createdAt,
    ExecutionStatus status,
    double progress,
    List<ExecutionLogEntry> logs,
  ) => Execution(
    id: order.id,
    cliente: order.client,
    productos: List.unmodifiable(order.products),
    lineas: order.lines,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    estado: status,
    progreso: progress,
    bitacora: List.unmodifiable(logs),
  );

  ExecutionLogEntry _log(ExecutionStatus status, String message) =>
      ExecutionLogEntry(
        timestamp: DateTime.now(),
        message: message,
        status: status,
      );
}
