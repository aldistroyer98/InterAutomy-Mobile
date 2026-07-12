import '../engine/automation_context.dart';
import '../engine/automation_result.dart';
import '../state/automation_state.dart';
import '../waiting/retry_policy.dart';

abstract interface class AutomationStep {
  String get id;
  String get visibleName;
  AutomationState get initialState;
  AutomationState get finalState;
  Duration get timeout;
  RetryPolicy get retryPolicy;
  bool get canCancel;
  Future<AutomationResult> execute(AutomationContext context);
  Future<AutomationResult> verify(AutomationContext context);
}
