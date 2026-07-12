final class AutomationLogSanitizer {
  const AutomationLogSanitizer._();

  static String sanitize(String value) {
    return value
        .replaceAll(
          RegExp(
            r'(password|contrase(?:ñ|n)a|token|cookie)\s*[:=]\s*[^\s,;]+',
            caseSensitive: false,
          ),
          r'$1=[oculto]',
        )
        .replaceAll(
          RegExp(r'bearer\s+[a-z0-9._-]+', caseSensitive: false),
          'Bearer [oculto]',
        )
        .replaceAll(
          RegExp(
            r'([?&](?:token|code|session|key)=)[^&#\s]+',
            caseSensitive: false,
          ),
          r'$1[oculto]',
        )
        .replaceAll(
          RegExp(
            r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
            caseSensitive: false,
          ),
          '[correo oculto]',
        )
        .replaceAll(
          RegExp(r'(NRO\s*OC\s*[:=]\s*)[A-Z0-9._/-]{5,}', caseSensitive: false),
          r'$1[oculto]',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String maskValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '****';
    final tail = trimmed.length <= 4
        ? trimmed
        : trimmed.substring(trimmed.length - 4);
    return '****$tail';
  }
}
