import '../models/user_settings.dart';
import 'json_store.dart';

class SettingsRepository {
  final JsonStore _store = JsonStore('settings.json');
  UserSettings? _cache;

  Future<UserSettings> load() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await _store.read();
    final settings =
        raw == null ? UserSettings() : UserSettings.fromJson(raw as Map<String, dynamic>);
    _cache = settings;
    return settings;
  }

  Future<void> save(UserSettings settings) async {
    _cache = settings;
    await _store.write(settings.toJson());
  }
}
