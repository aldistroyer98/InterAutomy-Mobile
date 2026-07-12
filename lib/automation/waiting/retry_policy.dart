final class RetryPolicy {
  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 300),
    this.backoffFactor = 2,
  }) : assert(maxAttempts > 0),
       assert(backoffFactor >= 1);

  final int maxAttempts;
  final Duration initialDelay;
  final double backoffFactor;

  Duration delayForAttempt(int attempt) {
    final milliseconds =
        initialDelay.inMilliseconds *
        _pow(backoffFactor, attempt.clamp(0, maxAttempts - 1));
    return Duration(milliseconds: milliseconds.round());
  }

  static double _pow(double base, int exponent) {
    var result = 1.0;
    for (var index = 0; index < exponent; index++) {
      result *= base;
    }
    return result;
  }

  bool shouldRetry(RetryReason reason) => switch (reason) {
    RetryReason.selectorPending ||
    RetryReason.loading ||
    RetryReason.domChanging ||
    RetryReason.temporarilyDisabled => true,
    RetryReason.domainBlocked ||
    RetryReason.invalidSsl ||
    RetryReason.selectorAbsent ||
    RetryReason.incompatibleStructure ||
    RetryReason.crossOriginFrame ||
    RetryReason.cancelled ||
    RetryReason.sessionExpired => false,
  };
}

enum RetryReason {
  selectorPending,
  loading,
  domChanging,
  temporarilyDisabled,
  domainBlocked,
  invalidSsl,
  selectorAbsent,
  incompatibleStructure,
  crossOriginFrame,
  cancelled,
  sessionExpired,
}
