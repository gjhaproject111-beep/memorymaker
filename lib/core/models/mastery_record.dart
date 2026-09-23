class MasteryRecord {
  final String sessionId;
  final String passageId;
  final int attemptsToMastery;
  final double firstAttemptAccuracy;
  final double finalAttemptAccuracy;
  final int totalTrainingMs; // reading + recall time, summed across attempts
  final DateTime masteredAt;

  const MasteryRecord({
    required this.sessionId,
    required this.passageId,
    required this.attemptsToMastery,
    required this.firstAttemptAccuracy,
    required this.finalAttemptAccuracy,
    required this.totalTrainingMs,
    required this.masteredAt,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'passageId': passageId,
        'attemptsToMastery': attemptsToMastery,
        'firstAttemptAccuracy': firstAttemptAccuracy,
        'finalAttemptAccuracy': finalAttemptAccuracy,
        'totalTrainingMs': totalTrainingMs,
        'masteredAt': masteredAt.toIso8601String(),
      };

  factory MasteryRecord.fromJson(Map<String, dynamic> json) => MasteryRecord(
        sessionId: json['sessionId'] as String,
        passageId: json['passageId'] as String,
        attemptsToMastery: json['attemptsToMastery'] as int,
        firstAttemptAccuracy: (json['firstAttemptAccuracy'] as num).toDouble(),
        finalAttemptAccuracy: (json['finalAttemptAccuracy'] as num).toDouble(),
        totalTrainingMs: json['totalTrainingMs'] as int,
        masteredAt: DateTime.parse(json['masteredAt'] as String),
      );
}
