import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/api_configuration_repository.dart';
import '../../domain/repositories/settings_repository.dart';

final class LocalSettingsRepository
    implements SettingsRepository, ApiConfigurationRepository {
  LocalSettingsRepository({
    required this.defaultApiUrl,
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _demoKey = 'settings.demo_mode';
  static const _apiKey = 'settings.api_url';
  static const _themeKey = 'settings.theme';
  static const _futureTokenKey = 'future_api_token';

  final String defaultApiUrl;
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
      apiUrl: preferences.getString(_apiKey) ?? defaultApiUrl,
      theme: theme,
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setBool(_demoKey, settings.demoMode),
      preferences.setString(_apiKey, settings.apiUrl),
      preferences.setString(_themeKey, settings.theme.name),
    ]);
  }

  @override
  Future<String> getBaseUrl() async => (await load()).apiUrl;

  @override
  Future<void> setBaseUrl(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_apiKey, value);
  }

  @override
  Future<String?> readFutureToken() =>
      _secureStorage.read(key: _futureTokenKey);

  @override
  Future<void> saveFutureToken(String token) =>
      _secureStorage.write(key: _futureTokenKey, value: token);
}
