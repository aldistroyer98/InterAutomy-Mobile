import '../../app/app_config.dart';

final class PageStructureSummary {
  const PageStructureSummary({
    this.forms = 0,
    this.inputs = 0,
    this.selects = 0,
    this.buttons = 0,
    this.tables = 0,
    this.fileInputs = 0,
  });

  final int forms;
  final int inputs;
  final int selects;
  final int buttons;
  final int tables;
  final int fileInputs;

  factory PageStructureSummary.fromJson(Map<String, Object?> json) =>
      PageStructureSummary(
        forms: _integer(json['forms']),
        inputs: _integer(json['inputs']),
        selects: _integer(json['selects']),
        buttons: _integer(json['buttons']),
        tables: _integer(json['tables']),
        fileInputs: _integer(json['fileInputs']),
      );

  Map<String, Object?> toJson() => {
    'forms': forms,
    'inputs': inputs,
    'selects': selects,
    'buttons': buttons,
    'tables': tables,
    'fileInputs': fileInputs,
  };
}

final class FrameworkDetectionResult {
  const FrameworkDetectionResult({
    this.name = 'unknown',
    this.confidence = 0,
    this.signals = const [],
  });

  final String name;
  final double confidence;
  final List<String> signals;

  factory FrameworkDetectionResult.fromJson(Map<String, Object?> json) =>
      FrameworkDetectionResult(
        name: _safeText(json['name'], fallback: 'unknown'),
        confidence: _decimal(json['confidence']).clamp(0, 1),
        signals: _safeStringList(json['signals'], maximum: 8),
      );

  Map<String, Object?> toJson() => {
    'name': name,
    'confidence': confidence,
    'signals': signals,
  };
}

final class FrameInfo {
  const FrameInfo({
    required this.origin,
    this.source = '',
    this.name = '',
    this.id = '',
    this.visible = false,
  });

  final String origin;
  final String source;
  final String name;
  final String id;
  final bool visible;

  factory FrameInfo.fromJson(Map<String, Object?> json) => FrameInfo(
    origin:
        const {'sameOrigin', 'crossOrigin', 'unknown'}.contains(json['origin'])
        ? json['origin']! as String
        : 'unknown',
    source: _safeText(json['source']),
    name: _safeText(json['name']),
    id: _safeText(json['id']),
    visible: json['visible'] == true,
  );

  Map<String, Object?> toJson() => {
    'origin': origin,
    'source': source,
    'name': name,
    'id': id,
    'visible': visible,
  };
}

final class FrameSummary {
  const FrameSummary({this.frames = const [], this.nroOcCrossOrigin = false});

  final List<FrameInfo> frames;
  final bool nroOcCrossOrigin;

  int get total => frames.length;
  int get sameOrigin =>
      frames.where((frame) => frame.origin == 'sameOrigin').length;
  int get crossOrigin =>
      frames.where((frame) => frame.origin == 'crossOrigin').length;

  factory FrameSummary.fromJson(Map<String, Object?> json) {
    final raw = json['frames'];
    return FrameSummary(
      frames: raw is List
          ? List.unmodifiable(
              raw
                  .whereType<Map>()
                  .take(20)
                  .map(
                    (item) => FrameInfo.fromJson(
                      item.map((key, value) => MapEntry(key.toString(), value)),
                    ),
                  ),
            )
          : const [],
      nroOcCrossOrigin: json['nroOcCrossOrigin'] == true,
    );
  }

  Map<String, Object?> toJson() => {
    'total': total,
    'sameOrigin': sameOrigin,
    'crossOrigin': crossOrigin,
    'nroOcCrossOrigin': nroOcCrossOrigin,
    'frames': frames.map((frame) => frame.toJson()).toList(growable: false),
  };
}

final class ShadowDomSummary {
  const ShadowDomSummary({
    this.count = 0,
    this.hosts = const [],
    this.maxDepth = 0,
    this.inputCount = 0,
    this.possibleNroOc = false,
    this.truncated = false,
  });

  final int count;
  final List<String> hosts;
  final int maxDepth;
  final int inputCount;
  final bool possibleNroOc;
  final bool truncated;

  factory ShadowDomSummary.fromJson(Map<String, Object?> json) =>
      ShadowDomSummary(
        count: _integer(json['count']),
        hosts: _safeStringList(json['hosts'], maximum: 20),
        maxDepth: _integer(json['maxDepth']),
        inputCount: _integer(json['inputCount']),
        possibleNroOc: json['possibleNroOc'] == true,
        truncated: json['truncated'] == true,
      );

  Map<String, Object?> toJson() => {
    'count': count,
    'hosts': hosts,
    'maxDepth': maxDepth,
    'inputCount': inputCount,
    'possibleNroOc': possibleNroOc,
    'truncated': truncated,
  };
}

final class StorageAvailability {
  const StorageAvailability({
    this.sessionStorage = false,
    this.localStorage = false,
    this.cookies = false,
  });

  final bool sessionStorage;
  final bool localStorage;
  final bool cookies;

  factory StorageAvailability.fromJson(Map<String, Object?> json) =>
      StorageAvailability(
        sessionStorage: json['sessionStorage'] == true,
        localStorage: json['localStorage'] == true,
        cookies: json['cookies'] == true,
      );

  Map<String, Object?> toJson() => {
    'sessionStorage': sessionStorage,
    'localStorage': localStorage,
    'cookies': cookies,
  };
}

final class PopupDetectionResult {
  const PopupDetectionResult({
    this.detected = false,
    this.targetBlankCount = 0,
    this.externalLinkCount = 0,
    this.ssoLinkCount = 0,
  });

  final bool detected;
  final int targetBlankCount;
  final int externalLinkCount;
  final int ssoLinkCount;

  factory PopupDetectionResult.fromJson(Map<String, Object?> json) =>
      PopupDetectionResult(
        detected: json['detected'] == true,
        targetBlankCount: _integer(json['targetBlankCount']),
        externalLinkCount: _integer(json['externalLinkCount']),
        ssoLinkCount: _integer(json['ssoLinkCount']),
      );

  Map<String, Object?> toJson() => {
    'detected': detected,
    'targetBlankCount': targetBlankCount,
    'externalLinkCount': externalLinkCount,
    'ssoLinkCount': ssoLinkCount,
  };
}

final class SelectorAlternativeProbe {
  const SelectorAlternativeProbe({
    required this.index,
    this.found = false,
    this.visible = false,
    this.enabled = false,
    this.elementType = '',
    this.tag = '',
    this.sameOrigin = true,
    this.insideShadowDom = false,
    this.insideIframe = false,
  });

  final int index;
  final bool found;
  final bool visible;
  final bool enabled;
  final String elementType;
  final String tag;
  final bool sameOrigin;
  final bool insideShadowDom;
  final bool insideIframe;

  factory SelectorAlternativeProbe.fromJson(Map<String, Object?> json) =>
      SelectorAlternativeProbe(
        index: _integer(json['index']),
        found: json['found'] == true,
        visible: json['visible'] == true,
        enabled: json['enabled'] == true,
        elementType: _safeText(json['elementType']),
        tag: _safeText(json['tag']),
        sameOrigin: json['sameOrigin'] != false,
        insideShadowDom: json['insideShadowDom'] == true,
        insideIframe: json['insideIframe'] == true,
      );

  Map<String, Object?> toJson() => {
    'index': index,
    'found': found,
    'visible': visible,
    'enabled': enabled,
    'elementType': elementType,
    'tag': tag,
    'sameOrigin': sameOrigin,
    'insideShadowDom': insideShadowDom,
    'insideIframe': insideIframe,
  };
}

final class SelectorProbeResult {
  const SelectorProbeResult({
    this.success = false,
    this.code = 'NOT_PROBED',
    this.logicalKey = 'purchaseOrderNumber',
    this.alternativeIndex,
    this.visible = false,
    this.enabled = false,
    this.elapsedMilliseconds = 0,
    this.retries = 0,
    this.elementType = '',
    this.tag = '',
    this.sameOrigin = true,
    this.insideShadowDom = false,
    this.insideIframe = false,
    this.alternatives = const [],
    this.version = AppConfig.selectorVersion,
  });

  final bool success;
  final String code;
  final String logicalKey;
  final int? alternativeIndex;
  final bool visible;
  final bool enabled;
  final int elapsedMilliseconds;
  final int retries;
  final String elementType;
  final String tag;
  final bool sameOrigin;
  final bool insideShadowDom;
  final bool insideIframe;
  final List<SelectorAlternativeProbe> alternatives;
  final String version;

  factory SelectorProbeResult.fromJson(
    Map<String, Object?> json,
  ) => SelectorProbeResult(
    success: json['success'] == true,
    code: _safeText(json['code'], fallback: 'UNKNOWN_PROBE'),
    logicalKey: _safeText(json['logicalKey'], fallback: 'purchaseOrderNumber'),
    alternativeIndex: json['alternativeIndex'] is num
        ? (json['alternativeIndex'] as num).toInt()
        : null,
    visible: json['visible'] == true,
    enabled: json['enabled'] == true,
    elapsedMilliseconds: _integer(json['elapsedMilliseconds']),
    retries: _integer(json['retries']),
    elementType: _safeText(json['elementType']),
    tag: _safeText(json['tag']),
    sameOrigin: json['sameOrigin'] != false,
    insideShadowDom: json['insideShadowDom'] == true,
    insideIframe: json['insideIframe'] == true,
    alternatives: json['alternatives'] is List
        ? List.unmodifiable(
            (json['alternatives'] as List).whereType<Map>().map(
              (item) => SelectorAlternativeProbe.fromJson(
                item.map((key, value) => MapEntry(key.toString(), value)),
              ),
            ),
          )
        : const [],
    version: _safeText(json['version'], fallback: AppConfig.selectorVersion),
  );

  Map<String, Object?> toJson() => {
    'success': success,
    'code': code,
    'logicalKey': logicalKey,
    'alternativeIndex': alternativeIndex,
    'visible': visible,
    'enabled': enabled,
    'elapsedMilliseconds': elapsedMilliseconds,
    'retries': retries,
    'elementType': elementType,
    'tag': tag,
    'sameOrigin': sameOrigin,
    'insideShadowDom': insideShadowDom,
    'insideIframe': insideIframe,
    'alternatives': alternatives
        .map((alternative) => alternative.toJson())
        .toList(growable: false),
    'version': version,
  };
}

final class PortalFingerprint {
  const PortalFingerprint({
    this.value = '',
    this.version = AppConfig.fingerprintVersion,
    this.recognized = false,
    this.signals = const [],
  });

  final String value;
  final String version;
  final bool recognized;
  final List<String> signals;

  factory PortalFingerprint.fromJson(Map<String, Object?> json) =>
      PortalFingerprint(
        value: _safeText(json['value']),
        version: _safeText(
          json['version'],
          fallback: AppConfig.fingerprintVersion,
        ),
        recognized: json['recognized'] == true,
        signals: _safeStringList(json['signals'], maximum: 12),
      );

  Map<String, Object?> toJson() => {
    'value': value,
    'version': version,
    'recognized': recognized,
    'signals': signals,
  };
}

final class WebDiagnosticSnapshot {
  const WebDiagnosticSnapshot({
    required this.timestamp,
    required this.sanitizedUrl,
    required this.host,
    required this.title,
    required this.loadingState,
    required this.detectedPage,
    required this.framework,
    required this.structure,
    required this.frames,
    required this.shadowDom,
    required this.storage,
    required this.popup,
    required this.fingerprint,
    this.selectorProbe = const SelectorProbeResult(),
    this.lastError,
    this.engineVersion = 'WebView Android del sistema',
    this.workflowVersion = AppConfig.workflowVersion,
    this.selectorVersion = AppConfig.selectorVersion,
  });

  final DateTime timestamp;
  final String sanitizedUrl;
  final String host;
  final String title;
  final String loadingState;
  final String detectedPage;
  final FrameworkDetectionResult framework;
  final PageStructureSummary structure;
  final FrameSummary frames;
  final ShadowDomSummary shadowDom;
  final StorageAvailability storage;
  final PopupDetectionResult popup;
  final PortalFingerprint fingerprint;
  final SelectorProbeResult selectorProbe;
  final String? lastError;
  final String engineVersion;
  final String workflowVersion;
  final String selectorVersion;

  Map<String, Object?> toJson() => {
    'timestamp': timestamp.toUtc().toIso8601String(),
    'url': sanitizedUrl,
    'host': host,
    'title': title,
    'loadingState': loadingState,
    'detectedPage': detectedPage,
    'framework': framework.toJson(),
    'structure': structure.toJson(),
    'frames': frames.toJson(),
    'shadowDom': shadowDom.toJson(),
    'storage': storage.toJson(),
    'popup': popup.toJson(),
    'fingerprint': fingerprint.toJson(),
    'selectorProbe': selectorProbe.toJson(),
    'lastError': lastError,
    'engineVersion': engineVersion,
    'workflowVersion': workflowVersion,
    'selectorVersion': selectorVersion,
  };
}

int _integer(Object? value) => value is num ? value.toInt() : 0;
double _decimal(Object? value) => value is num ? value.toDouble() : 0;

String _safeText(Object? value, {String fallback = ''}) {
  final text = value
      ?.toString()
      .replaceAll(RegExp(r'[\u0000-\u001f]'), '')
      .trim();
  if (text == null || text.isEmpty) return fallback;
  return text.length <= 180 ? text : text.substring(0, 180);
}

List<String> _safeStringList(Object? value, {required int maximum}) =>
    value is List
    ? List.unmodifiable(
        value
            .map((item) => _safeText(item))
            .where((item) => item.isNotEmpty)
            .take(maximum),
      )
    : const [];
