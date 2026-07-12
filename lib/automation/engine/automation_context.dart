import '../../domain/entities/order.dart';
import '../state/automation_state.dart';

final class AutomationContext {
  AutomationContext({
    required this.executionId,
    required this.order,
    required this.createdAt,
  });

  final String executionId;
  final Order order;
  final DateTime createdAt;
  AutomationState state = AutomationState.idle;
  bool cancelled = false;
  String? lastSelector;
  int retryCount = 0;
}
