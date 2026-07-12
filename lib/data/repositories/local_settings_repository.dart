import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/api_configuration_repository.dart';
import '../../domain/repositories/settings_repository.dart';

final class LocalSettingsRepository
    implements SettingsRepository, ApiConfigurationRepository {
  LocalSettingsRepository({
    required this.defaultPortalUrl,
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _demoKey = 'settings.demo_mode';
  static const _portalKey = 'settings.portal_url';
  static const _legacyApiKey = 'settings.api_url';
  static const _additionalHostsKey = 'settings.additional_allowed_hosts';
  static const _developerModeKey = 'settings.developer_mode';
  static const _diagnosticModeKey = 'settings.diagnostic_mode';
  static const _persistSessionKey = 'settings.persist_session';
  static const _loadTimeoutKey = 'settings.load_timeout_seconds';
  static const _selectorTimeoutKey = 'settings.selector_timeout_seconds';
  static const _themeKey = 'settings.theme';
  static const _futureTokenKey = 'future_api_token';

  final String defaultPortalUrl;
  final FlutterSecureStorage _secureStorage;

  @override
  Future<AppSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    final themeName = preferences.getString(_themeKey);
    final theme = AppThemePreference.values.firstWhere(
      (value) => value.name == themeName,
      orElse: () => AppThemePreference.system,
    );
    return AppSettings(
      demoMode: preferences.getBool(_demoKey) ?? true,
      portalUrl:
          preferences.getString(_portalKey) ??
          preferences.getString(_legacyApiKey) ??
          defaultPortalUrl,
      additionalAllowedHosts:
          preferences.getStringList(_additionalHostsKey) ?? const [],
      developerMode: preferences.getBool(_developerModeKey) ?? false,
      diagnosticMode: preferences.getBool(_diagnosticModeKey) ?? false,
      persistSession: preferences.getBool(_persistSessionKey) ?? true,
      loadTimeoutSeconds: preferences.getInt(_loadTimeoutKey) ?? 45,
      selectorTimeoutSeconds: preferences.getInt(_selectorTimeoutKey) ?? 12,
      theme: theme,
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setBool(_demoKey, settings.demoMode),
      preferences.setString(_portalKey, settings.portalUrl),
      preferences.setStringList(
        _additionalHostsKey,
        settings.additionalAllowedHosts,
      ),
      preferences.setBool(_developerModeKey, settings.developerMode),
      preferences.setBool(_diagnosticModeKey, settings.diagnosticMode),
      preferences.setBool(_persistSessionKey, settings.persistSession),
      preferences.setInt(_loadTimeoutKey, settings.loadTimeoutSeconds),
      preferences.setInt(_selectorTimeoutKey, settings.selectorTimeoutSeconds),
      preferences.setString(_themeKey, settings.theme.name),
    ]);
  }

  @override
  Future<String> getBaseUrl() async => (await load()).portalUrl;

  @override
  Future<void> setBaseUrl(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_portalKey, value);
  }

  @override
  Future<String?> readFutureToken() =>
      _secureStorage.read(key: _futureTokenKey);

  @override
  Future<void> saveFutureToken(String token) =>
      _secureStorage.write(key: _futureTokenKey, value: token);
}
