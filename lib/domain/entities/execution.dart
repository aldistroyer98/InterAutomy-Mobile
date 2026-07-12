import 'client.dart';
import 'commercial_line.dart';
import 'product.dart';

enum ExecutionStatus {
  pending,
  validating,
  queued,
  startingAgent,
  startingBrowser,
  fillingInformation,
  waitingForReview,
  completed,
  failed,
  cancelled,
}

extension ExecutionStatusLabel on ExecutionStatus {
  String get label => switch (this) {
    ExecutionStatus.pending => 'Pendiente',
    ExecutionStatus.validating => 'Validando',
    ExecutionStatus.queued => 'En cola',
    ExecutionStatus.startingAgent => 'Iniciando agente',
    ExecutionStatus.startingBrowser => 'Iniciando navegador',
    ExecutionStatus.fillingInformation => 'Completando información',
    ExecutionStatus.waitingForReview => 'Esperando revisión',
    ExecutionStatus.completed => 'Completado',
    ExecutionStatus.failed => 'Fallido',
    ExecutionStatus.cancelled => 'Cancelado',
  };

  bool get isTerminal =>
      this == ExecutionStatus.completed ||
      this == ExecutionStatus.failed ||
      this == ExecutionStatus.cancelled;
}

final class ExecutionLogEntry {
  const ExecutionLogEntry({
    required this.timestamp,
    required this.message,
    required this.status,
  });

  final DateTime timestamp;
  final String message;
  final ExecutionStatus status;
}

final class Execution {
  const Execution({
    required this.id,
    required this.cliente,
    required this.productos,
    required this.lineas,
    required this.createdAt,
    required this.updatedAt,
    required this.estado,
    required this.progreso,
    required this.bitacora,
    this.mensajeError,
  });

  final String id;
  final Client cliente;
  final List<SelectedProduct> productos;
  final List<CommercialLine> lineas;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ExecutionStatus estado;
  final double progreso;
  final List<ExecutionLogEntry> bitacora;
  final String? mensajeError;

  double get total => productos.fold(0, (sum, item) => sum + item.subtotal);

  Execution copyWith({
    DateTime? updatedAt,
    ExecutionStatus? estado,
    double? progreso,
    List<ExecutionLogEntry>? bitacora,
    String? mensajeError,
    bool clearError = false,
  }) {
    return Execution(
      id: id,
      cliente: cliente,
      productos: productos,
      lineas: lineas,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      estado: estado ?? this.estado,
      progreso: progreso ?? this.progreso,
      bitacora: bitacora ?? this.bitacora,
      mensajeError: clearError ? null : mensajeError ?? this.mensajeError,
    );
  }
}
