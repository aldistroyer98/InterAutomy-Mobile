import '../entities/app_settings.dart';

abstract interface class SettingsRepository {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
  Future<void> saveFutureToken(String token);
  Future<String?> readFutureToken();
}
