import 'enums.dart';

/// A single persisted, categorized error produced by the comparison engine
/// for one recall attempt. Stored so Analytics can aggregate error-type
/// trends over time without re-running the comparison.
class ErrorRecord {
  final String id;
  final String attemptId;
  final String passageId;
  final ErrorType type;
  final String? originalWord;
  final String? recalledWord;
  final int position; // index within the original passage, for context
  final DateTime createdAt;

  ErrorRecord({
    required this.id,
    required this.attemptId,
    required this.passageId,
    required this.type,
    required this.position,
    required this.createdAt,
    this.originalWord,
    this.recalledWord,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'attemptId': attemptId,
        'passageId': passageId,
        'type': type.name,
        'originalWord': originalWord,
        'recalledWord': recalledWord,
        'position': position,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ErrorRecord.fromJson(Map<String, dynamic> json) => ErrorRecord(
        id: json['id'] as String,
        attemptId: json['attemptId'] as String,
        passageId: json['passageId'] as String,
        type: ErrorTypeX.fromName(json['type'] as String),
        originalWord: json['originalWord'] as String?,
        recalledWord: json['recalledWord'] as String?,
        position: json['position'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
