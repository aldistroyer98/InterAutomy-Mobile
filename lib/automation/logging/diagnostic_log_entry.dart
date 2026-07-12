final class DiagnosticLogEntry {
  const DiagnosticLogEntry({required this.timestamp, required this.event});

  final DateTime timestamp;
  final String event;

  Map<String, Object?> toJson() => {
    'timestamp': timestamp.toUtc().toIso8601String(),
    'event': event,
  };
}
