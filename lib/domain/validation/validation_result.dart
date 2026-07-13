enum ValidationSeverity { error, warning }

final class ValidationIssue {
  const ValidationIssue({
    required this.code,
    required this.field,
    required this.message,
    required this.severity,
    required this.correctiveAction,
  });

  final String code;
  final String field;
  final String message;
  final ValidationSeverity severity;
  final String correctiveAction;
}

final class ValidationResult {
  const ValidationResult(this.issues);

  const ValidationResult.valid() : issues = const [];

  final List<ValidationIssue> issues;

  List<ValidationIssue> get errors => List.unmodifiable(
    issues.where((issue) => issue.severity == ValidationSeverity.error),
  );

  List<ValidationIssue> get warnings => List.unmodifiable(
    issues.where((issue) => issue.severity == ValidationSeverity.warning),
  );

  bool get valid => errors.isEmpty;
}
