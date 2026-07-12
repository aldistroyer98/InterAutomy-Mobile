import '../../app/app_config.dart';
import 'diagnostic_models.dart';

abstract final class PortalFingerprintBuilder {
  static PortalFingerprint build({
    required String host,
    required String path,
    required String title,
    required Iterable<String> selectorKeys,
    required int controlCount,
    required String framework,
    String workflowVersion = AppConfig.workflowVersion,
  }) {
    final keys =
        selectorKeys
            .map(_normalize)
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final signals = <String>[
      _normalize(host),
      _normalizedPath(path),
      _normalize(title),
      keys.join(','),
      _controlBucket(controlCount),
      _normalize(framework),
      workflowVersion,
    ];
    final canonical = signals.join('|');
    final recognized = keys.contains('purchaseordernumber');
    return PortalFingerprint(
      value: _fnv1a(canonical),
      recognized: recognized,
      signals: [
        if (keys.isNotEmpty) 'selectors:${keys.join(',')}',
        'controls:${_controlBucket(controlCount)}',
        'framework:${_normalize(framework)}',
      ],
    );
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[^a-z0-9._,/ -]'), '')
      .trim();

  static String _normalizedPath(String value) => _normalize(value)
      .replaceAll(RegExp(r'/[0-9a-f]{8,}'), '/:id')
      .replaceAll(RegExp(r'/\d+'), '/:id');

  static String _controlBucket(int count) => switch (count) {
    <= 0 => '0',
    <= 5 => '1-5',
    <= 20 => '6-20',
    <= 50 => '21-50',
    _ => '51+',
  };

  static String _fnv1a(String value) {
    var hash = 0x811c9dc5;
    for (final byte in value.codeUnits) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
