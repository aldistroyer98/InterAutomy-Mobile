import '../detection/page_detector.dart';

final class PortalDiagnostics {
  const PortalDiagnostics({
    this.url,
    this.title = 'Sin título',
    this.loadingProgress = 0,
    this.javascriptAvailable = false,
    this.cookiesAvailable = false,
    this.iframeCount = 0,
    this.fileInputCount = 0,
    this.popupLinkCount = 0,
    this.page = PortalPage.unknown,
    this.lastError,
    this.engineVersion = 'WebView Android del sistema',
  });

  final Uri? url;
  final String title;
  final int loadingProgress;
  final bool javascriptAvailable;
  final bool cookiesAvailable;
  final int iframeCount;
  final int fileInputCount;
  final int popupLinkCount;
  final PortalPage page;
  final String? lastError;
  final String engineVersion;

  String get host => url?.host ?? 'Sin host';
  bool get isLoading => loadingProgress > 0 && loadingProgress < 100;
  String get fingerprint => '${page.name}-1';

  PortalDiagnostics copyWith({
    Uri? url,
    String? title,
    int? loadingProgress,
    bool? javascriptAvailable,
    bool? cookiesAvailable,
    int? iframeCount,
    int? fileInputCount,
    int? popupLinkCount,
    PortalPage? page,
    String? lastError,
    bool clearError = false,
    String? engineVersion,
  }) => PortalDiagnostics(
    url: url ?? this.url,
    title: title ?? this.title,
    loadingProgress: loadingProgress ?? this.loadingProgress,
    javascriptAvailable: javascriptAvailable ?? this.javascriptAvailable,
    cookiesAvailable: cookiesAvailable ?? this.cookiesAvailable,
    iframeCount: iframeCount ?? this.iframeCount,
    fileInputCount: fileInputCount ?? this.fileInputCount,
    popupLinkCount: popupLinkCount ?? this.popupLinkCount,
    page: page ?? this.page,
    lastError: clearError ? null : lastError ?? this.lastError,
    engineVersion: engineVersion ?? this.engineVersion,
  );
}
