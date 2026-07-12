enum AutomationOutcome {
  success,
  retryableFailure,
  fatalFailure,
  waitingForUser,
  cancelled,
}

final class AutomationResult {
  const AutomationResult({
    required this.outcome,
    required this.code,
    required this.message,
    this.data = const {},
  });

  final AutomationOutcome outcome;
  final String code;
  final String message;
  final Map<String, Object?> data;

  bool get isSuccess => outcome == AutomationOutcome.success;
}
