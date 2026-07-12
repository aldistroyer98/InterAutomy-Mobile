import 'package:interautomy_mobile/domain/entities/app_settings.dart';
import 'package:interautomy_mobile/domain/repositories/settings_repository.dart';

final class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({
    this.settings = const AppSettings(
      demoMode: true,
      apiUrl: 'http://localhost:8000',
      theme: AppThemePreference.system,
    ),
  });

  AppSettings settings;
  String? token;

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<void> save(AppSettings settings) async => this.settings = settings;

  @override
  Future<String?> readFutureToken() async => token;

  @override
  Future<void> saveFutureToken(String token) async => this.token = token;
}
