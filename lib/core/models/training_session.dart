import 'enums.dart';
import 'recall_attempt.dart';
import 'mastery_record.dart';
import 'retention_test.dart';

/// The full journey for one passage: every recall attempt until mastery,
/// the mastery result, and the delayed-retention tests scheduled after it.
class TrainingSession {
  final String id;
  final String passageId;
  final DateTime startedAt;
  SessionStatus status;
  final bool isBaseline;
  final List<RecallAttempt> attempts;
  MasteryRecord? masteryRecord;
  final List<RetentionTest> retentionTests;

  TrainingSession({
    required this.id,
    required this.passageId,
    required this.startedAt,
    required this.status,
    this.isBaseline = false,
    List<RecallAttempt>? attempts,
    this.masteryRecord,
    List<RetentionTest>? retentionTests,
  })  : attempts = attempts ?? [],
        retentionTests = retentionTests ?? [];

  bool get isMastered => status == SessionStatus.mastered;

  Map<String, dynamic> toJson() => {
        'id': id,
        'passageId': passageId,
        'startedAt': startedAt.toIso8601String(),
        'status': status.name,
        'isBaseline': isBaseline,
        'attempts': attempts.map((a) => a.toJson()).toList(),
        'masteryRecord': masteryRecord?.toJson(),
        'retentionTests': retentionTests.map((r) => r.toJson()).toList(),
      };

  factory TrainingSession.fromJson(Map<String, dynamic> json) => TrainingSession(
        id: json['id'] as String,
        passageId: json['passageId'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        status: SessionStatusX.fromName(json['status'] as String),
        isBaseline: json['isBaseline'] as bool? ?? false,
        attempts: (json['attempts'] as List<dynamic>? ?? [])
            .map((e) => RecallAttempt.fromJson(e as Map<String, dynamic>))
            .toList(),
        masteryRecord: json['masteryRecord'] == null
            ? null
            : MasteryRecord.fromJson(json['masteryRecord'] as Map<String, dynamic>),
        retentionTests: (json['retentionTests'] as List<dynamic>? ?? [])
            .map((e) => RetentionTest.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
