import 'enums.dart';

class RetentionTest {
  final String id;
  final String sessionId;
  final String passageId;
  final RetentionInterval interval;
  final DateTime scheduledAt;
  DateTime? completedAt;
  double? accuracy; // exact word accuracy of the retention attempt
  String? attemptId; // links to the RecallAttempt used for this test

  RetentionTest({
    required this.id,
    required this.sessionId,
    required this.passageId,
    required this.interval,
    required this.scheduledAt,
    this.completedAt,
    this.accuracy,
    this.attemptId,
  });

  bool get isDue => completedAt == null && DateTime.now().isAfter(scheduledAt);
  bool get isCompleted => completedAt != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'passageId': passageId,
        'interval': interval.name,
        'scheduledAt': scheduledAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'accuracy': accuracy,
        'attemptId': attemptId,
      };

  factory RetentionTest.fromJson(Map<String, dynamic> json) => RetentionTest(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        passageId: json['passageId'] as String,
        interval: RetentionIntervalX.fromName(json['interval'] as String),
        scheduledAt: DateTime.parse(json['scheduledAt'] as String),
        completedAt: json['completedAt'] == null ? null : DateTime.parse(json['completedAt'] as String),
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        attemptId: json['attemptId'] as String?,
      );
}
