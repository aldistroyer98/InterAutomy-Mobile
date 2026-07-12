import 'dart:convert';

final class JavascriptResult {
  const JavascriptResult({
    required this.success,
    required this.code,
    required this.message,
    this.retryable = false,
    this.data = const {},
  });

  final bool success;
  final String code;
  final String message;
  final bool retryable;
  final Map<String, Object?> data;

  factory JavascriptResult.fromPlatformValue(Object? value) {
    final decoded = _decode(value);
    if (decoded is! Map) {
      return const JavascriptResult(
        success: false,
        code: 'INVALID_SCRIPT_RESPONSE',
        message: 'El script no devolvió un objeto JSON válido.',
      );
    }
    final data = decoded['data'];
    return JavascriptResult(
      success: decoded['success'] == true,
      code: decoded['code']?.toString() ?? 'UNKNOWN_SCRIPT_RESULT',
      message:
          decoded['message']?.toString() ?? 'Respuesta JavaScript sin mensaje.',
      retryable: decoded['retryable'] == true,
      data: data is Map
          ? data.map((key, value) => MapEntry(key.toString(), value))
          : const {},
    );
  }

  static Object? _decode(Object? value) {
    if (value is String) {
      try {
        final first = jsonDecode(value);
        return first is String ? jsonDecode(first) : first;
      } on FormatException {
        return null;
      }
    }
    return value;
  }
}
