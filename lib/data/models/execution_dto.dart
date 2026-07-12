final class ExecutionDto {
  const ExecutionDto({
    required this.id,
    required this.status,
    required this.progress,
  });

  factory ExecutionDto.fromJson(Map<String, Object?> json) => ExecutionDto(
    id: json['id'] as String? ?? '',
    status: json['status'] as String? ?? 'pending',
    progress: (json['progress'] as num?)?.toDouble() ?? 0,
  );

  final String id;
  final String status;
  final double progress;

  Map<String, Object?> toJson() => {
    'id': id,
    'status': status,
    'progress': progress,
  };
}
