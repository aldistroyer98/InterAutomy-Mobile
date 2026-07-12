import 'automation_step.dart';

final class WorkflowDefinition {
  const WorkflowDefinition({required this.version, required this.steps});

  final String version;
  final List<AutomationStep> steps;
}
