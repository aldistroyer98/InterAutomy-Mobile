enum NavigationEventType {
  initial,
  redirect,
  allowed,
  blocked,
  pageFinished,
  sslError,
  dnsError,
  timeout,
  cancelled,
  otherError,
}

final class NavigationDiagnosticEvent {
  const NavigationDiagnosticEvent({
    required this.timestamp,
    required this.type,
    required this.decision,
    required this.reason,
    this.fromUrl = '',
    this.toUrl = '',
    this.fromHost = '',
    this.toHost = '',
  });

  final DateTime timestamp;
  final NavigationEventType type;
  final String decision;
  final String reason;
  final String fromUrl;
  final String toUrl;
  final String fromHost;
  final String toHost;

  Map<String, Object?> toJson() => {
    'timestamp': timestamp.toUtc().toIso8601String(),
    'type': type.name,
    'decision': decision,
    'reason': reason,
    'fromUrl': fromUrl,
    'toUrl': toUrl,
    'fromHost': fromHost,
    'toHost': toHost,
  };
}
