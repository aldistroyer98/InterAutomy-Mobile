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
    required this.theme,
  });

  final bool demoMode;
  final String portalUrl;
  final List<String> additionalAllowedHosts;
  final AppThemePreference theme;

  bool get hasPortalConfiguration => portalUrl.trim().isNotEmpty;

  AppSettings copyWith({
    bool? demoMode,
    String? portalUrl,
    List<String>? additionalAllowedHosts,
    AppThemePreference? theme,
  }) => AppSettings(
    demoMode: demoMode ?? this.demoMode,
    portalUrl: portalUrl ?? this.portalUrl,
    additionalAllowedHosts:
        additionalAllowedHosts ?? this.additionalAllowedHosts,
    theme: theme ?? this.theme,
  );
}
