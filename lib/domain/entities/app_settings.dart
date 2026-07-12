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
    required this.theme,
  });

  final bool demoMode;
  final String portalUrl;
  final List<String> additionalAllowedHosts;
  final bool developerMode;
  final bool diagnosticMode;
  final AppThemePreference theme;

  bool get hasPortalConfiguration => portalUrl.trim().isNotEmpty;

  AppSettings copyWith({
    bool? demoMode,
    String? portalUrl,
    List<String>? additionalAllowedHosts,
    bool? developerMode,
    bool? diagnosticMode,
    AppThemePreference? theme,
  }) => AppSettings(
    demoMode: demoMode ?? this.demoMode,
    portalUrl: portalUrl ?? this.portalUrl,
    additionalAllowedHosts:
        additionalAllowedHosts ?? this.additionalAllowedHosts,
    developerMode: developerMode ?? this.developerMode,
    diagnosticMode: diagnosticMode ?? this.diagnosticMode,
    theme: theme ?? this.theme,
  );
}
