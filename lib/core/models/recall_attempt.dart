class RecallAttempt {
  final String id;
  final String sessionId;
  final String passageId;
  final int attemptNumber; // 1-based
  final bool isRetentionTest;
  final int readingDurationMs;
  final int recallDurationMs;
  final String recalledText;
  final DateTime createdAt;

  // Denormalized scoring summary, cached at comparison time so Analytics
  // doesn't need to re-run the comparison engine over full history.
  final int originalWordCount;
  final int recalledWordCount;
  final int correctWordCount;
  final int missingCount;
  final int extraCount;
  final int substitutionCount;
  final int orderErrorCount;
  final int spellingErrorCount;
  final double exactWordAccuracy;
  final double orderAccuracy;

  const RecallAttempt({
    required this.id,
    required this.sessionId,
    required this.passageId,
    required this.attemptNumber,
    required this.isRetentionTest,
    required this.readingDurationMs,
    required this.recallDurationMs,
    required this.recalledText,
    required this.createdAt,
    required this.originalWordCount,
    required this.recalledWordCount,
    required this.correctWordCount,
    required this.missingCount,
    required this.extraCount,
    required this.substitutionCount,
    required this.orderErrorCount,
    required this.spellingErrorCount,
    required this.exactWordAccuracy,
    required this.orderAccuracy,
  });

  double get wordsPerMinute {
    if (readingDurationMs <= 0) return 0;
    final minutes = readingDurationMs / 60000.0;
    return originalWordCount / minutes;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'passageId': passageId,
        'attemptNumber': attemptNumber,
        'isRetentionTest': isRetentionTest,
        'readingDurationMs': readingDurationMs,
        'recallDurationMs': recallDurationMs,
        'recalledText': recalledText,
        'createdAt': createdAt.toIso8601String(),
        'originalWordCount': originalWordCount,
        'recalledWordCount': recalledWordCount,
        'correctWordCount': correctWordCount,
        'missingCount': missingCount,
        'extraCount': extraCount,
        'substitutionCount': substitutionCount,
        'orderErrorCount': orderErrorCount,
        'spellingErrorCount': spellingErrorCount,
        'exactWordAccuracy': exactWordAccuracy,
        'orderAccuracy': orderAccuracy,
      };

  factory RecallAttempt.fromJson(Map<String, dynamic> json) => RecallAttempt(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        passageId: json['passageId'] as String,
        attemptNumber: json['attemptNumber'] as int,
        isRetentionTest: json['isRetentionTest'] as bool? ?? false,
        readingDurationMs: json['readingDurationMs'] as int,
        recallDurationMs: json['recallDurationMs'] as int,
        recalledText: json['recalledText'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        originalWordCount: json['originalWordCount'] as int,
        recalledWordCount: json['recalledWordCount'] as int,
        correctWordCount: json['correctWordCount'] as int,
        missingCount: json['missingCount'] as int,
        extraCount: json['extraCount'] as int,
        substitutionCount: json['substitutionCount'] as int,
        orderErrorCount: json['orderErrorCount'] as int,
        spellingErrorCount: json['spellingErrorCount'] as int,
        exactWordAccuracy: (json['exactWordAccuracy'] as num).toDouble(),
        orderAccuracy: (json['orderAccuracy'] as num).toDouble(),
      );
}
