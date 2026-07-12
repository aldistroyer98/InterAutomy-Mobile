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
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
