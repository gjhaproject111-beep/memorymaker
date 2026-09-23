import '../models/enums.dart';
import '../models/retention_test.dart';
import '../models/training_session.dart';
import 'json_store.dart';

/// Persists every [TrainingSession] (and, nested inside it, every attempt,
/// the mastery record, and retention tests) to a single local JSON file.
/// Small enough in practice for a single-user app that a full read/rewrite
/// per mutation is simple and safe rather than premature to optimize.
class SessionRepository {
  final JsonStore _store = JsonStore('sessions.json');
  List<TrainingSession>? _cache;

  Future<List<TrainingSession>> loadAll() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await _store.read();
    if (raw == null) {
      _cache = [];
      return _cache!;
    }
    final list = (raw as List<dynamic>)
        .map((e) => TrainingSession.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = list;
    return list;
  }

  Future<void> _persist() async {
    final cached = _cache ?? [];
    await _store.write(cached.map((s) => s.toJson()).toList());
  }

  Future<void> save(TrainingSession session) async {
    final list = await loadAll();
    final index = list.indexWhere((s) => s.id == session.id);
    if (index >= 0) {
      list[index] = session;
    } else {
      list.add(session);
    }
    await _persist();
  }

  /// Wholesale replace — used by backup restore and by "reset progress".
  Future<void> replaceAll(List<TrainingSession> sessions) async {
    _cache = sessions;
    await _persist();
  }

  /// The most recent session still in progress, if any — surfaced on Home
  /// as "You have an unfinished session" for recovery.
  Future<TrainingSession?> findRecoverable() async {
    final list = await loadAll();
    final inProgress = list.where((s) => s.status == SessionStatus.inProgress).toList();
    if (inProgress.isEmpty) return null;
    inProgress.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return inProgress.first;
  }

  Future<void> discard(String sessionId) async {
    final list = await loadAll();
    list.removeWhere((s) => s.id == sessionId);
    await _persist();
  }

  Future<Set<String>> usedPassageIds() async {
    final list = await loadAll();
    return list.map((s) => s.passageId).toSet();
  }

  Future<List<TrainingSession>> masteredSessions() async {
    final list = await loadAll();
    return list.where((s) => s.isMastered).toList()
      ..sort((a, b) => (a.masteryRecord?.masteredAt ?? a.startedAt)
          .compareTo(b.masteryRecord?.masteredAt ?? b.startedAt));
  }

  Future<List<TrainingSession>> baselineSessions() async {
    final list = await loadAll();
    return list.where((s) => s.isBaseline).toList();
  }

  /// Every retention test across every session, flattened, most-urgent-first.
  Future<List<({TrainingSession session, RetentionTest test})>> allRetentionTests() async {
    final list = await loadAll();
    final out = <({TrainingSession session, RetentionTest test})>[];
    for (final session in list) {
      for (final test in session.retentionTests) {
        out.add((session: session, test: test));
      }
    }
    out.sort((a, b) => a.test.scheduledAt.compareTo(b.test.scheduledAt));
    return out;
  }

  Future<List<({TrainingSession session, RetentionTest test})>> duePendingRetentionTests() async {
    final all = await allRetentionTests();
    return all.where((r) => !r.test.isCompleted && !DateTime.now().isBefore(r.test.scheduledAt)).toList();
  }

  Future<List<({TrainingSession session, RetentionTest test})>> upcomingRetentionTests() async {
    final all = await allRetentionTests();
    return all.where((r) => !r.test.isCompleted && DateTime.now().isBefore(r.test.scheduledAt)).toList();
  }
}
