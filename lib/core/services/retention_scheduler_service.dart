import '../models/enums.dart';
import '../models/retention_test.dart';
import '../utils/id_generator.dart';

/// Builds the delayed-retention checkpoints for a session the moment it
/// reaches mastery. Intervals are configurable via [UserSettings], defaulting
/// to all five (10 min / 24 hr / 3 day / 7 day / 30 day).
class RetentionSchedulerService {
  const RetentionSchedulerService();

  List<RetentionTest> scheduleFor({
    required String sessionId,
    required String passageId,
    required DateTime masteredAt,
    required List<RetentionInterval> intervals,
  }) {
    return intervals
        .map((interval) => RetentionTest(
              id: IdGenerator.next('retention'),
              sessionId: sessionId,
              passageId: passageId,
              interval: interval,
              scheduledAt: masteredAt.add(Duration(minutes: interval.minutesFromMastery)),
            ))
        .toList();
  }
}
