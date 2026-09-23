/// One point on a trend chart — a bucket (e.g. a week) of aggregated
/// performance, produced by ProgressRepository from raw sessions/attempts.
/// Not persisted on its own; always derived so it never goes stale.
class ProgressSnapshot {
  final DateTime bucketStart;
  final double oneReadAccuracy; // avg first-attempt exact accuracy in bucket
  final double averageAttemptsToMastery;
  final double averageReadingWpm;
  final double omissionRate;
  final double substitutionRate;
  final double orderErrorRate;
  final double extraWordRate;
  final double spellingErrorRate;
  final int sessionsCompleted;

  const ProgressSnapshot({
    required this.bucketStart,
    required this.oneReadAccuracy,
    required this.averageAttemptsToMastery,
    required this.averageReadingWpm,
    required this.omissionRate,
    required this.substitutionRate,
    required this.orderErrorRate,
    required this.extraWordRate,
    required this.spellingErrorRate,
    required this.sessionsCompleted,
  });
}
