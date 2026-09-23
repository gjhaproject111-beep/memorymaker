import '../models/training_session.dart';
import '../models/user_settings.dart';
import '../repositories/json_store.dart';
import '../repositories/session_repository.dart';
import '../repositories/settings_repository.dart';

/// Local backup/restore (spec §36 "Data: Export / Import / Reset").
///
/// Note on scope: this writes a real, readable JSON backup file into the
/// app's own local storage and can restore from it — a genuine round trip,
/// not a placeholder. It does not (yet) hand the file to Android's system
/// share sheet or a file picker, since that needs a platform-integration
/// package this project deliberately doesn't depend on for V1. Wiring
/// `share_plus`/`file_picker` in later is a clean, self-contained addition
/// — see the README.
class BackupService {
  BackupService(this._sessions, this._settings);

  final SessionRepository _sessions;
  final SettingsRepository _settings;
  final JsonStore _backupStore = JsonStore('backup.json');

  Future<void> exportBackup() async {
    final sessions = await _sessions.loadAll();
    final settings = await _settings.load();
    await _backupStore.write({
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': settings.toJson(),
      'sessions': sessions.map((s) => s.toJson()).toList(),
    });
  }

  Future<bool> restoreBackup() async {
    final raw = await _backupStore.read();
    if (raw == null) return false;
    final map = raw as Map<String, dynamic>;
    final settings = UserSettings.fromJson(map['settings'] as Map<String, dynamic>);
    final sessions =
        (map['sessions'] as List<dynamic>).map((e) => TrainingSession.fromJson(e as Map<String, dynamic>)).toList();
    await _settings.save(settings);
    await _sessions.replaceAll(sessions);
    return true;
  }

  Future<void> resetProgress() async {
    await _sessions.replaceAll([]);
  }
}
