import '../diagnostics/diagnostic_models.dart';
import '../diagnostics/portal_fingerprint_builder.dart';
import '../javascript/javascript_result.dart';
import '../javascript/javascript_runner.dart';
import '../logging/automation_log_sanitizer.dart';
import '../selectors/selector_registry.dart';
import '../webview/portal_diagnostics.dart';

enum PortalPage {
  unknown,
  login,
  home,
  processList,
  clientForm,
  productForm,
  review,
  success,
  error,
  sessionExpired,
  blockedBySecurity,
  unsupportedStructure,
}

final class PageDetector {
  PageDetector(this._runner);

  final JavascriptRunner _runner;

  Future<PortalDiagnostics> inspect(PortalDiagnostics previous) async {
    final selector = SelectorRegistry.byKey('purchaseOrderNumber');
    final payload = {
      'nroOcAlternatives': selector.alternatives,
      'selectorVersion': selector.version,
    };
    final results = await Future.wait([
      _runner.run('diagnostics', payload: payload),
      _runner.run('framework_detection', payload: payload),
      _runner.run('iframe_detection', payload: payload),
      _runner.run('shadow_dom_detection', payload: payload),
    ]);
    final diagnostic = results[0];
    if (!diagnostic.success) {
      return previous.copyWith(lastError: diagnostic.message);
    }
    final data = diagnostic.data;
    final url = Uri.tryParse(data['url']?.toString() ?? '') ?? previous.url;
    final title = _safeTitle(data['title']?.toString());
    final structure = PageStructureSummary.fromJson(_map(data['structure']));
    final framework = _framework(results[1]);
    final frames = _frames(results[2]);
    final shadowDom = _shadow(results[3]);
    final storage = StorageAvailability.fromJson(_map(data['storage']));
    final popup = PopupDetectionResult.fromJson(_map(data['popup']));
    final signals = _strings(data['pageSignals']);
    final selectorKeys = _strings(data['selectorKeys']);
    final fingerprint = PortalFingerprintBuilder.build(
      host: url?.host ?? '',
      path: url?.path ?? '',
      title: title,
      selectorKeys: selectorKeys,
      controlCount: structure.inputs + structure.selects + structure.buttons,
      framework: framework.name,
    );
    final page = detect(
      url: url,
      title: title,
      signals: signals,
      blockedBySecurity: false,
      fingerprintRecognized: fingerprint.recognized,
    );
    return previous.copyWith(
      timestamp: DateTime.now(),
      url: url,
      title: title,
      javascriptAvailable: true,
      framework: framework,
      structure: structure,
      frames: frames,
      shadowDom: shadowDom,
      storage: storage,
      popup: popup,
      portalFingerprint: fingerprint,
      page: page,
      engineVersion: _engineFromUserAgent(data['userAgent']?.toString()),
      lastStep: 'DIAGNOSTIC_COMPLETED',
      clearError: true,
    );
  }

  static PortalPage detect({
    required Uri? url,
    required String title,
    required Iterable<String> signals,
    required bool blockedBySecurity,
    required bool fingerprintRecognized,
  }) {
    final found = signals.toSet();
    final urlAndTitle = '${url?.path ?? ''} $title'.toLowerCase();
    if (blockedBySecurity || found.contains('blockedBySecurity')) {
      return PortalPage.blockedBySecurity;
    }
    if (found.contains('sessionExpired') ||
        urlAndTitle.contains('session expired') ||
        urlAndTitle.contains('sesión expirada')) {
      return PortalPage.sessionExpired;
    }
    if (found.contains('error')) return PortalPage.error;
    if (found.contains('success')) return PortalPage.success;
    if (found.contains('login') || urlAndTitle.contains('login')) {
      return PortalPage.login;
    }
    if (found.contains('review')) return PortalPage.review;
    if (found.contains('clientForm')) {
      return fingerprintRecognized
          ? PortalPage.clientForm
          : PortalPage.unsupportedStructure;
    }
    if (found.contains('processList')) return PortalPage.processList;
    if (found.contains('home')) return PortalPage.home;
    return PortalPage.unknown;
  }

  static FrameworkDetectionResult _framework(JavascriptResult result) =>
      result.success
      ? FrameworkDetectionResult.fromJson(result.data)
      : const FrameworkDetectionResult();

  static FrameSummary _frames(JavascriptResult result) => result.success
      ? FrameSummary.fromJson(result.data)
      : const FrameSummary();

  static ShadowDomSummary _shadow(JavascriptResult result) => result.success
      ? ShadowDomSummary.fromJson(result.data)
      : const ShadowDomSummary();

  static Map<String, Object?> _map(Object? value) => value is Map
      ? value.map((key, value) => MapEntry(key.toString(), value))
      : const {};

  static List<String> _strings(Object? value) =>
      value is List ? value.map((item) => item.toString()).toList() : const [];

  static String _safeTitle(String? value) {
    final title = AutomationLogSanitizer.sanitize(
      value?.replaceAll(RegExp(r'[\u0000-\u001f]'), '').trim() ?? '',
    ).replaceAll(RegExp(r'\b\d{5,}\b'), '[id oculto]');
    if (title.isEmpty) return 'Sin título';
    return title.length <= 120 ? title : title.substring(0, 120);
  }

  static String _engineFromUserAgent(String? value) {
    if (value == null || value.isEmpty) return 'WebView Android del sistema';
    final match = RegExp(r'(Chrome/[0-9.]+)').firstMatch(value);
    return match?.group(1) ?? 'WebView Android del sistema';
  }
}
