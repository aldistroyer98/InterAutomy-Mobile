import 'dart:convert';

final class JavascriptPayloadEncoder {
  const JavascriptPayloadEncoder._();

  static String encode(Map<String, Object?> payload) => jsonEncode(payload);
}
