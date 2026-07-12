final class AutomationException implements Exception {
  const AutomationException(
    this.message, {
    this.code = 'AUTOMATION_ERROR',
    this.retryable = false,
  });

  final String message;
  final String code;
  final bool retryable;

  @override
  String toString() => '$code: $message';
}
