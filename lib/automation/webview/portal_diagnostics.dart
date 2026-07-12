import '../../app/app_config.dart';
import '../../core/security/webview_security_policy.dart';
import '../detection/page_detector.dart';
import '../diagnostics/diagnostic_models.dart';

final class PortalDiagnostics {
  const PortalDiagnostics({
    this.timestamp,
    this.url,
    this.title = 'Sin título',
    this.loadingProgress = 0,
    this.javascriptAvailable = false,
    this.framework = const FrameworkDetectionResult(),
    this.structure = const PageStructureSummary(),
    this.frames = const FrameSummary(),
    this.shadowDom = const ShadowDomSummary(),
    this.storage = const StorageAvailability(),
    this.popup = const PopupDetectionResult(),
    this.selectorProbe = const SelectorProbeResult(),
    this.page = PortalPage.unknown,
    this.portalFingerprint = const PortalFingerprint(),
    this.lastSelectorLogical,
    this.lastStep,
    this.lastError,
    this.engineVersion = 'WebView Android del sistema',
  });

  final DateTime? timestamp;
  final Uri? url;
  final String title;
  final int loadingProgress;
  final bool javascriptAvailable;
  final FrameworkDetectionResult framework;
  final PageStructureSummary structure;
  final FrameSummary frames;
  final ShadowDomSummary shadowDom;
  final StorageAvailability storage;
  final PopupDetectionResult popup;
  final SelectorProbeResult selectorProbe;
  final PortalPage page;
  final PortalFingerprint portalFingerprint;
  final String? lastSelectorLogical;
  final String? lastStep;
  final String? lastError;
  final String engineVersion;

  String get host => url?.host ?? 'Sin host';
  String get scheme => url?.scheme ?? 'Sin esquema';
  String get port =>
      url == null || !url!.hasPort ? 'Predeterminado' : '${url!.port}';
  bool get isLoading => loadingProgress > 0 && loadingProgress < 100;
  int get iframeCount => frames.total;
  int get fileInputCount => structure.fileInputs;
  int get popupLinkCount => popup.targetBlankCount;
  bool get cookiesAvailable => storage.cookies;
  String get fingerprint => portalFingerprint.value;

  WebDiagnosticSnapshot toSnapshot() => WebDiagnosticSnapshot(
    timestamp: timestamp ?? DateTime.now(),
    sanitizedUrl: WebViewSecurityPolicy.displayUrl(url),
    host: host,
    title: title,
    loadingState: isLoading
        ? 'loading'
        : loadingProgress == 100
        ? 'ready'
        : 'idle',
    detectedPage: page.name,
    framework: framework,
    structure: structure,
    frames: frames,
    shadowDom: shadowDom,
    storage: storage,
    popup: popup,
    fingerprint: portalFingerprint,
    selectorProbe: selectorProbe,
    lastError: lastError,
    engineVersion: engineVersion,
    workflowVersion: AppConfig.workflowVersion,
    selectorVersion: AppConfig.selectorVersion,
  );

  PortalDiagnostics copyWith({
    DateTime? timestamp,
    Uri? url,
    String? title,
    int? loadingProgress,
    bool? javascriptAvailable,
    FrameworkDetectionResult? framework,
    PageStructureSummary? structure,
    FrameSummary? frames,
    ShadowDomSummary? shadowDom,
    StorageAvailability? storage,
    PopupDetectionResult? popup,
    SelectorProbeResult? selectorProbe,
    PortalPage? page,
    PortalFingerprint? portalFingerprint,
    String? lastSelectorLogical,
    String? lastStep,
    String? lastError,
    bool clearError = false,
    String? engineVersion,
  }) => PortalDiagnostics(
    timestamp: timestamp ?? this.timestamp,
    url: url ?? this.url,
    title: title ?? this.title,
    loadingProgress: loadingProgress ?? this.loadingProgress,
    javascriptAvailable: javascriptAvailable ?? this.javascriptAvailable,
    framework: framework ?? this.framework,
    structure: structure ?? this.structure,
    frames: frames ?? this.frames,
    shadowDom: shadowDom ?? this.shadowDom,
    storage: storage ?? this.storage,
    popup: popup ?? this.popup,
    selectorProbe: selectorProbe ?? this.selectorProbe,
    page: page ?? this.page,
    portalFingerprint: portalFingerprint ?? this.portalFingerprint,
    lastSelectorLogical: lastSelectorLogical ?? this.lastSelectorLogical,
    lastStep: lastStep ?? this.lastStep,
    lastError: clearError ? null : lastError ?? this.lastError,
    engineVersion: engineVersion ?? this.engineVersion,
  );
}
