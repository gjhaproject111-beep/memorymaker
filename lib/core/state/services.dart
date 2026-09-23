import 'package:flutter/foundation.dart';

import '../repositories/passage_repository.dart';
import '../repositories/progress_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/settings_repository.dart';
import '../services/backup_service.dart';
import '../services/passage_selector_service.dart';
import '../services/retention_scheduler_service.dart';
import '../services/scoring_service.dart';
import '../services/text_comparison_service.dart';

/// A small, dependency-free service locator. Every dependency here is a
/// cheap, effectively-stateless singleton, so a full DI framework would be
/// more machinery than a single-user local app needs.
class Services {
  Services._();

  static final PassageRepository passages = PassageRepository();
  static final SessionRepository sessions = SessionRepository();
  static final SettingsRepository settings = SettingsRepository();
  static final ProgressRepository progress = ProgressRepository(sessions, passages);
  static const TextComparisonService comparison = TextComparisonService();
  static const ScoringService scoring = ScoringService();
  static const RetentionSchedulerService retentionScheduler = RetentionSchedulerService();
  static final PassageSelectorService passageSelector = PassageSelectorService(passages, sessions);
  static final BackupService backup = BackupService(sessions, settings);
}

/// A tiny event bus screens listen to so they know to refetch after data
/// changes elsewhere (a session saved, a setting changed) — avoids pulling
/// in a state-management package for what is, in this app, an occasional
/// "please refresh" signal rather than continuous shared state.
class AppDataBus extends ChangeNotifier {
  AppDataBus._();
  static final AppDataBus instance = AppDataBus._();

  void notifyChanged() => notifyListeners();
}
