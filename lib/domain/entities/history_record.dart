import 'execution.dart';
import 'client.dart';
import 'product.dart';

final class HistoryRecord {
  const HistoryRecord({
    required this.id,
    required this.executionId,
    required this.clientId,
    required this.clientName,
    required this.lineNames,
    required this.createdAt,
    required this.status,
    required this.products,
    this.clientSnapshot,
    this.executionMode = 'Demo',
    this.result = '',
    this.totalSnapshot,
  });

  factory HistoryRecord.fromExecution(
    Execution execution, {
    required String executionMode,
  }) => HistoryRecord(
    id: execution.id,
    executionId: execution.id,
    clientId: execution.cliente.id,
    clientName: execution.cliente.nombre,
    lineNames: execution.lineas
        .map((line) => line.nombre)
        .toList(growable: false),
    createdAt: execution.updatedAt,
    status: execution.estado,
    products: List.unmodifiable(execution.productos),
    clientSnapshot: execution.cliente,
    executionMode: executionMode,
    result: execution.mensajeError ?? execution.estado.label,
    totalSnapshot: execution.total,
  );

  final String id;
  final String executionId;
  final String clientId;
  final String clientName;
  final List<String> lineNames;
  final DateTime createdAt;
  final ExecutionStatus status;
  final List<SelectedProduct> products;
  final Client? clientSnapshot;
  final String executionMode;
  final String result;
  final double? totalSnapshot;

  double get total =>
      totalSnapshot ??
      products.fold(0, (sum, product) => sum + product.subtotal);
}
