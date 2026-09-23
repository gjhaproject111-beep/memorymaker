import '../models/enums.dart';
import '../models/progress_snapshot.dart';
import '../models/recall_attempt.dart';
import '../models/training_session.dart';
import 'passage_repository.dart';
import 'session_repository.dart';

/// A metric bundled with how it changed vs. the prior 7-day window, e.g.
/// "72%, +6% this week". [delta] is null when there isn't a full prior
/// window of data yet to compare against.
class TrendedValue {
  final double value;
  final double? delta;
  const TrendedValue(this.value, this.delta);
}

class HomeSummary {
  final TrendedValue? oneReadAccuracy;
  final TrendedValue? attemptsToMastery;
  final TrendedValue? sevenDayRetention;
  final int currentStreakDays;
  final int totalPassagesMastered;
  final int totalSessionsStarted;

  const HomeSummary({
    required this.oneReadAccuracy,
    required this.attemptsToMastery,
    required this.sevenDayRetention,
    required this.currentStreakDays,
    required this.totalPassagesMastered,
    required this.totalSessionsStarted,
  });
}

class ErrorRateBreakdown {
  final double omissionRate;
  final double substitutionRate;
  final double orderErrorRate;
  final double extraWordRate;
  final double spellingErrorRate;

  const ErrorRateBreakdown({
    required this.omissionRate,
    required this.substitutionRate,
    required this.orderErrorRate,
    required this.extraWordRate,
    required this.spellingErrorRate,
  });

  static const zero = ErrorRateBreakdown(
    omissionRate: 0,
    substitutionRate: 0,
    orderErrorRate: 0,
    extraWordRate: 0,
    spellingErrorRate: 0,
  );
}

/// Derives every progress/analytics figure from raw sessions — nothing here
/// is stored independently, so it can never drift out of sync with the
/// underlying attempts.
class ProgressRepository {
  ProgressRepository(this._sessions, this._passages);

  final SessionRepository _sessions;
  final PassageRepository _passages;

  Future<List<RecallAttempt>> _allAttempts() async {
    final sessions = await _sessions.loadAll();
    return sessions.expand((s) => s.attempts).toList();
  }

  double? _average(Iterable<double> values) {
    final list = values.toList();
    if (list.isEmpty) return null;
    return list.reduce((a, b) => a + b) / list.length;
  }

  Future<double?> oneReadAccuracy({DateTime? since, DateTime? until}) async {
    final attempts = await _allAttempts();
    final firstAttempts = attempts.where((a) =>
        a.attemptNumber == 1 &&
        !a.isRetentionTest &&
        (since == null || a.createdAt.isAfter(since)) &&
        (until == null || a.createdAt.isBefore(until)));
    return _average(firstAttempts.map((a) => a.exactWordAccuracy));
  }

  Future<double?> averageAttemptsToMastery({DateTime? since, DateTime? until}) async {
    final sessions = await _sessions.masteredSessions();
    final relevant = sessions.where((s) {
      final at = s.masteryRecord?.masteredAt;
      if (at == null) return false;
      if (since != null && !at.isAfter(since)) return false;
      if (until != null && !at.isBefore(until)) return false;
      return true;
    });
    return _average(relevant.map((s) => s.masteryRecord!.attemptsToMastery.toDouble()));
  }

  Future<double?> retentionAccuracyFor(RetentionInterval interval, {DateTime? since, DateTime? until}) async {
    final all = await _sessions.allRetentionTests();
    final relevant = all.where((r) {
      if (r.test.interval != interval || !r.test.isCompleted) return false;
      final at = r.test.completedAt!;
      if (since != null && !at.isAfter(since)) return false;
      if (until != null && !at.isBefore(until)) return false;
      return true;
    });
    return _average(relevant.map((r) => r.test.accuracy!));
  }

  Future<double?> averageReadingWpm({DateTime? since, DateTime? until}) async {
    final attempts = await _allAttempts();
    final relevant = attempts.where((a) =>
        a.readingDurationMs > 0 &&
        (since == null || a.createdAt.isAfter(since)) &&
        (until == null || a.createdAt.isBefore(until)));
    return _average(relevant.map((a) => a.wordsPerMinute));
  }

  /// One-read accuracy grouped by the passage's difficulty — answers
  /// "does harder material hurt my first-pass accuracy?" (spec §24).
  Future<Map<PassageDifficulty, double?>> accuracyByDifficulty() async {
    final attempts = await _allAttempts();
    final passages = await _passages.loadAll();
    final difficultyById = {for (final p in passages) p.id: p.difficulty};

    final byDifficulty = <PassageDifficulty, List<double>>{
      for (final d in PassageDifficulty.values) d: [],
    };
    for (final a in attempts) {
      if (a.attemptNumber != 1 || a.isRetentionTest) continue;
      final difficulty = difficultyById[a.passageId];
      if (difficulty == null) continue;
      byDifficulty[difficulty]!.add(a.exactWordAccuracy);
    }
    return {for (final entry in byDifficulty.entries) entry.key: _average(entry.value)};
  }

  Future<ErrorRateBreakdown> errorRateBreakdown({DateTime? since, DateTime? until}) async {
    final attempts = await _allAttempts();
    final relevant = attempts
        .where((a) =>
            a.originalWordCount > 0 &&
            (since == null || a.createdAt.isAfter(since)) &&
            (until == null || a.createdAt.isBefore(until)))
        .toList();
    if (relevant.isEmpty) return ErrorRateBreakdown.zero;

    var words = 0, missing = 0, subs = 0, order = 0, extra = 0, spelling = 0;
    for (final a in relevant) {
      words += a.originalWordCount;
      missing += a.missingCount;
      subs += a.substitutionCount;
      order += a.orderErrorCount;
      extra += a.extraCount;
      spelling += a.spellingErrorCount;
    }
    if (words == 0) return ErrorRateBreakdown.zero;
    return ErrorRateBreakdown(
      omissionRate: missing / words,
      substitutionRate: subs / words,
      orderErrorRate: order / words,
      extraWordRate: extra / words,
      spellingErrorRate: spelling / words,
    );
  }

  Future<int> currentStreakDays() async {
    final attempts = await _allAttempts();
    if (attempts.isEmpty) return 0;
    final days = attempts.map((a) => DateTime(a.createdAt.year, a.createdAt.month, a.createdAt.day)).toSet();
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);
    var streak = 0;
    // Today not having an attempt yet shouldn't zero out an otherwise-live
    // streak — start counting from today, but don't require it.
    if (!days.contains(cursor)) {
      final yesterday = cursor.subtract(const Duration(days: 1));
      if (!days.contains(yesterday)) return 0;
    }
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    if (streak == 0) {
      // Handle the "haven't trained today yet, but trained yesterday" case.
      cursor = DateTime.now();
      cursor = DateTime(cursor.year, cursor.month, cursor.day).subtract(const Duration(days: 1));
      while (days.contains(cursor)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
    }
    return streak;
  }

  Future<HomeSummary> homeSummary() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final twoWeeksAgo = now.subtract(const Duration(days: 14));

    final thisWeekAccuracy = await oneReadAccuracy(since: weekAgo, until: now);
    final lastWeekAccuracy = await oneReadAccuracy(since: twoWeeksAgo, until: weekAgo);
    final overallAccuracy = await oneReadAccuracy();

    final thisWeekAttempts = await averageAttemptsToMastery(since: weekAgo, until: now);
    final lastWeekAttempts = await averageAttemptsToMastery(since: twoWeeksAgo, until: weekAgo);
    final overallAttempts = await averageAttemptsToMastery();

    final thisWeekRetention = await retentionAccuracyFor(RetentionInterval.sevenDays, since: weekAgo, until: now);
    final lastWeekRetention =
        await retentionAccuracyFor(RetentionInterval.sevenDays, since: twoWeeksAgo, until: weekAgo);
    final overallRetention = await retentionAccuracyFor(RetentionInterval.sevenDays);

    final sessions = await _sessions.loadAll();
    final streak = await currentStreakDays();

    return HomeSummary(
      oneReadAccuracy: overallAccuracy == null
          ? null
          : TrendedValue(overallAccuracy,
              (thisWeekAccuracy != null && lastWeekAccuracy != null) ? thisWeekAccuracy - lastWeekAccuracy : null),
      attemptsToMastery: overallAttempts == null
          ? null
          : TrendedValue(overallAttempts,
              (thisWeekAttempts != null && lastWeekAttempts != null) ? thisWeekAttempts - lastWeekAttempts : null),
      sevenDayRetention: overallRetention == null
          ? null
          : TrendedValue(overallRetention,
              (thisWeekRetention != null && lastWeekRetention != null)
                  ? thisWeekRetention - lastWeekRetention
                  : null),
      currentStreakDays: streak,
      totalPassagesMastered: sessions.where((s) => s.isMastered).length,
      totalSessionsStarted: sessions.length,
    );
  }

  /// One [ProgressSnapshot] per week, oldest first, for trend charts.
  Future<List<ProgressSnapshot>> weeklyTrend({int weeks = 8}) async {
    final attempts = await _allAttempts();
    final masteredSessions = await _sessions.masteredSessions();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final snapshots = <ProgressSnapshot>[];

    for (var w = weeks - 1; w >= 0; w--) {
      final bucketStart = today.subtract(Duration(days: 7 * (w + 1) - today.weekday + 1));
      final bucketEnd = bucketStart.add(const Duration(days: 7));
      final inBucket = attempts
          .where((a) => !a.createdAt.isBefore(bucketStart) && a.createdAt.isBefore(bucketEnd))
          .toList();
      final firstAttempts = inBucket.where((a) => a.attemptNumber == 1 && !a.isRetentionTest).toList();
      final masteredInBucket = masteredSessions.where((s) {
        final at = s.masteryRecord?.masteredAt;
        return at != null && !at.isBefore(bucketStart) && at.isBefore(bucketEnd);
      });

      double avg(Iterable<double> vals) {
        final list = vals.toList();
        return list.isEmpty ? 0 : list.reduce((a, b) => a + b) / list.length;
      }

      final words = inBucket.fold<int>(0, (sum, a) => sum + a.originalWordCount);
      double rate(int Function(RecallAttempt) selector) =>
          words == 0 ? 0 : inBucket.fold<int>(0, (sum, a) => sum + selector(a)) / words;

      snapshots.add(ProgressSnapshot(
        bucketStart: bucketStart,
        oneReadAccuracy: avg(firstAttempts.map((a) => a.exactWordAccuracy)),
        averageAttemptsToMastery: avg(masteredInBucket.map((s) => s.masteryRecord!.attemptsToMastery.toDouble())),
        averageReadingWpm: avg(inBucket.where((a) => a.readingDurationMs > 0).map((a) => a.wordsPerMinute)),
        omissionRate: rate((a) => a.missingCount),
        substitutionRate: rate((a) => a.substitutionCount),
        orderErrorRate: rate((a) => a.orderErrorCount),
        extraWordRate: rate((a) => a.extraCount),
        spellingErrorRate: rate((a) => a.spellingErrorCount),
        sessionsCompleted: inBucket.map((a) => a.sessionId).toSet().length,
      ));
    }
    return snapshots;
  }
}
