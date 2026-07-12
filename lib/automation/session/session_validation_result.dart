final class SessionValidationResult {
  const SessionValidationResult({
    this.sessionDetected = false,
    this.persistedAfterPortalClose = false,
    this.persistedAfterBackground = false,
    this.persistedAfterAppRestart = false,
    this.expired = false,
    this.logoutVerified = false,
    this.cookiesCleared = false,
    this.notes = '',
    this.timestamp,
  });

  final bool sessionDetected;
  final bool persistedAfterPortalClose;
  final bool persistedAfterBackground;
  final bool persistedAfterAppRestart;
  final bool expired;
  final bool logoutVerified;
  final bool cookiesCleared;
  final String notes;
  final DateTime? timestamp;

  SessionValidationResult copyWith({
    bool? sessionDetected,
    bool? persistedAfterPortalClose,
    bool? persistedAfterBackground,
    bool? persistedAfterAppRestart,
    bool? expired,
    bool? logoutVerified,
    bool? cookiesCleared,
    String? notes,
    DateTime? timestamp,
  }) => SessionValidationResult(
    sessionDetected: sessionDetected ?? this.sessionDetected,
    persistedAfterPortalClose:
        persistedAfterPortalClose ?? this.persistedAfterPortalClose,
    persistedAfterBackground:
        persistedAfterBackground ?? this.persistedAfterBackground,
    persistedAfterAppRestart:
        persistedAfterAppRestart ?? this.persistedAfterAppRestart,
    expired: expired ?? this.expired,
    logoutVerified: logoutVerified ?? this.logoutVerified,
    cookiesCleared: cookiesCleared ?? this.cookiesCleared,
    notes: notes ?? this.notes,
    timestamp: timestamp ?? this.timestamp,
  );

  Map<String, Object?> toJson() => {
    'sessionDetected': sessionDetected,
    'persistedAfterPortalClose': persistedAfterPortalClose,
    'persistedAfterBackground': persistedAfterBackground,
    'persistedAfterAppRestart': persistedAfterAppRestart,
    'expired': expired,
    'logoutVerified': logoutVerified,
    'cookiesCleared': cookiesCleared,
    'notes': notes,
    'timestamp': timestamp?.toUtc().toIso8601String(),
  };
}
