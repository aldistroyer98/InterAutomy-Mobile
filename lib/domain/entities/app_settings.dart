import 'catalog_source.dart';

enum AppThemePreference { system, light, dark }

extension AppThemePreferenceLabel on AppThemePreference {
  String get label => switch (this) {
    AppThemePreference.system => 'Sistema',
    AppThemePreference.light => 'Claro',
    AppThemePreference.dark => 'Oscuro',
  };
}

final class AppSettings {
  const AppSettings({
    required this.demoMode,
    required this.portalUrl,
    this.additionalAllowedHosts = const [],
    this.developerMode = false,
    this.diagnosticMode = false,
    this.persistSession = true,
    this.loadTimeoutSeconds = 45,
    this.selectorTimeoutSeconds = 12,
    this.catalogSource = CatalogSource.demo,
    required this.theme,
  });

  final bool demoMode;
  final String portalUrl;
  final List<String> additionalAllowedHosts;
  final bool developerMode;
  final bool diagnosticMode;
  final bool persistSession;
  final int loadTimeoutSeconds;
  final int selectorTimeoutSeconds;
  final CatalogSource catalogSource;
  final AppThemePreference theme;

  bool get hasPortalConfiguration => portalUrl.trim().isNotEmpty;

  AppSettings copyWith({
    bool? demoMode,
    String? portalUrl,
    List<String>? additionalAllowedHosts,
    bool? developerMode,
    bool? diagnosticMode,
    bool? persistSession,
    int? loadTimeoutSeconds,
    int? selectorTimeoutSeconds,
    CatalogSource? catalogSource,
    AppThemePreference? theme,
  }) => AppSettings(
    demoMode: demoMode ?? this.demoMode,
    portalUrl: portalUrl ?? this.portalUrl,
    additionalAllowedHosts:
        additionalAllowedHosts ?? this.additionalAllowedHosts,
    developerMode: developerMode ?? this.developerMode,
    diagnosticMode: diagnosticMode ?? this.diagnosticMode,
    persistSession: persistSession ?? this.persistSession,
    loadTimeoutSeconds: loadTimeoutSeconds ?? this.loadTimeoutSeconds,
    selectorTimeoutSeconds:
        selectorTimeoutSeconds ?? this.selectorTimeoutSeconds,
    catalogSource: catalogSource ?? this.catalogSource,
    theme: theme ?? this.theme,
  );
}
