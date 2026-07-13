import 'package:interautomy_mobile/domain/entities/app_settings.dart';
import 'package:interautomy_mobile/domain/repositories/settings_repository.dart';

final class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({
    this.settings = const AppSettings(
      demoMode: true,
      portalUrl: '',
      theme: AppThemePreference.system,
    ),
  });

  AppSettings settings;

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<void> save(AppSettings settings) async => this.settings = settings;
}
