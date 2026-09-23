import '../models/comparison_result.dart';
import '../models/recall_attempt.dart';
import '../utils/id_generator.dart';

/// Turns a [ComparisonResult] plus attempt-timing data into a persisted,
/// denormalized [RecallAttempt] record — the single source of truth every
/// screen (Results, Review, Progress, Analytics) reads from afterward.
class ScoringService {
  const ScoringService();

  RecallAttempt buildAttempt({
    required String sessionId,
    required String passageId,
    required int attemptNumber,
    required bool isRetentionTest,
    required Duration readingDuration,
    required Duration recallDuration,
    required ComparisonResult comparison,
  }) {
    return RecallAttempt(
      id: IdGenerator.next('attempt'),
      sessionId: sessionId,
      passageId: passageId,
      attemptNumber: attemptNumber,
      isRetentionTest: isRetentionTest,
      readingDurationMs: readingDuration.inMilliseconds,
      recallDurationMs: recallDuration.inMilliseconds,
      recalledText: comparison.recalledText,
      createdAt: DateTime.now(),
      originalWordCount: comparison.originalWordCount,
      recalledWordCount: comparison.recalledWordCount,
      correctWordCount: comparison.correctWordCount,
      missingCount: comparison.missingWords.length,
      extraCount: comparison.extraWords.length,
      substitutionCount: comparison.substitutions.length,
      orderErrorCount: comparison.orderErrors.length,
      spellingErrorCount: comparison.spellingErrors.length,
      exactWordAccuracy: comparison.exactWordAccuracy,
      orderAccuracy: comparison.orderAccuracy,
    );
  }

  bool reachedMastery(ComparisonResult comparison, double masteryThreshold) =>
      comparison.isMastery(masteryThreshold);
}
