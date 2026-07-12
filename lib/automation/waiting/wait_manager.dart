import '../engine/automation_exception.dart';

final class WaitManager {
  const WaitManager({this.pollInterval = const Duration(milliseconds: 500)});

  final Duration pollInterval;

  Future<T> until<T>({
    required Future<T> Function() probe,
    required bool Function(T value) matches,
    required Duration timeout,
    required bool Function() isCancelled,
    String timeoutMessage = 'Se agotó el tiempo de espera del portal.',
  }) async {
    final startedAt = DateTime.now();
    while (true) {
      if (isCancelled()) {
        throw const AutomationException('Acción cancelada.', code: 'CANCELLED');
      }
      final value = await probe();
      if (matches(value)) return value;
      if (DateTime.now().difference(startedAt) >= timeout) {
        throw AutomationException(
          timeoutMessage,
          code: 'WAIT_TIMEOUT',
          retryable: true,
        );
      }
      await Future<void>.delayed(pollInterval);
    }
  }
}
