import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_config.dart';
import '../data/repositories/local_settings_repository.dart';
import '../domain/entities/app_settings.dart';
import '../domain/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) =>
      LocalSettingsRepository(defaultPortalUrl: AppConfig.defaultPortalUrl),
);

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

/// Fuente única de configuración de la aplicación.
///
/// No depende de controladores de flujo ni de gateways, por lo que puede ser
/// usada para elegir el motor Demo/WebView sin introducir dependencias inversas.
final class SettingsController extends Notifier<AppSettings> {
  Future<AppSettings>? _loading;
  var _initialized = false;

  @override
  AppSettings build() => const AppSettings(
    demoMode: true,
    portalUrl: AppConfig.defaultPortalUrl,
    theme: AppThemePreference.system,
  );

  Future<AppSettings> initialize() {
    if (_initialized) return Future.value(state);
    return _loading ??= _load();
  }

  Future<AppSettings> _load() async {
    try {
      state = await ref.read(settingsRepositoryProvider).load();
      _initialized = true;
      return state;
    } finally {
      _loading = null;
    }
  }

  Future<void> update(AppSettings settings) async {
    await ref.read(settingsRepositoryProvider).save(settings);
    state = settings;
    _initialized = true;
  }
}
