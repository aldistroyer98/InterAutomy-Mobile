import '../engine/automation_context.dart';
import '../engine/automation_exception.dart';
import '../engine/automation_result.dart';
import 'workflow_definition.dart';

final class WorkflowRunner {
  const WorkflowRunner();

  Future<AutomationResult> run(
    WorkflowDefinition workflow,
    AutomationContext context,
  ) async {
    for (final step in workflow.steps) {
      if (context.cancelled) {
        return const AutomationResult(
          outcome: AutomationOutcome.cancelled,
          code: 'CANCELLED',
          message: 'Ejecución cancelada por el usuario.',
        );
      }
      AutomationResult? result;
      for (var attempt = 0; attempt < step.retryPolicy.maxAttempts; attempt++) {
        context.retryCount = attempt;
        result = await step.execute(context).timeout(step.timeout);
        if (result.outcome != AutomationOutcome.retryableFailure) break;
        await Future<void>.delayed(step.retryPolicy.delayForAttempt(attempt));
      }
      if (result == null) {
        throw AutomationException('El paso ${step.id} no devolvió resultado.');
      }
      if (!result.isSuccess) return result;
      final verification = await step.verify(context).timeout(step.timeout);
      if (!verification.isSuccess) return verification;
    }
    return const AutomationResult(
      outcome: AutomationOutcome.success,
      code: 'WORKFLOW_COMPLETED',
      message: 'Flujo de automatización terminado.',
    );
  }
}
