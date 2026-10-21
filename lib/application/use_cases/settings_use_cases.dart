import '../../domain/entities/app_settings.dart';
import '../../domain/errors/domain_error.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsUseCases {
  const SettingsUseCases(this._settings, {required this.clock});

  final SettingsRepository _settings;
  final DateTime Function() clock;

  Future<AppSettings> load() => _settings.load();

  Future<void> setBusinessName(String value) async {
    final String name = value.trim();
    if (name.isEmpty) {
      throw const ValidationError(
        'Ingresa el nombre del negocio.',
        field: 'businessName',
      );
    }
    if (name.length > 80) {
      throw const ValidationError(
        'Usa un nombre de hasta 80 caracteres.',
        field: 'businessName',
      );
    }
    await _settings.setValue('business_name', name, clock().toUtc());
  }
}
