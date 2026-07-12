import '../entities/execution.dart';
import '../entities/order.dart';

abstract interface class AutomationGateway {
  Stream<Execution> execute(Order order);
  Future<Execution> confirmBrowserClosed(String executionId);
  Future<void> cancel(String executionId);
}
