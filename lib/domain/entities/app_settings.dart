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
    required this.apiUrl,
    required this.theme,
  });

  final bool demoMode;
  final String apiUrl;
  final AppThemePreference theme;

  AppSettings copyWith({
    bool? demoMode,
    String? apiUrl,
    AppThemePreference? theme,
  }) => AppSettings(
    demoMode: demoMode ?? this.demoMode,
    apiUrl: apiUrl ?? this.apiUrl,
    theme: theme ?? this.theme,
  );
}
