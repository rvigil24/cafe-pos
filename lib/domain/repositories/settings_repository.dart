import '../entities/app_settings.dart';

abstract interface class SettingsRepository {
  Future<AppSettings> load();

  Future<void> setValue(String key, String value, DateTime updatedAt);
}
