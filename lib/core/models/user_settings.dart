import 'enums.dart';

class UserSettings {
  int defaultPassageLength; // 90 / 120 / 150 / 200 / 300 / 500
  PassageDifficulty defaultDifficulty;
  double masteryThreshold; // 0.90–1.00, default 1.00 (100% exact)
  List<RetentionInterval> retentionIntervals;
  bool readingTimerEnabled;
  bool recallTimerEnabled;
  bool soundEnabled;
  bool requireExactPunctuation;
  bool showCorrectionsImmediately;
  bool autoAdvance;
  double fontScale; // 0.9 small, 1.0 medium, 1.15 large
  bool hasSeenOnboarding;
  bool hasCompletedBaseline;

  UserSettings({
    this.defaultPassageLength = 90,
    this.defaultDifficulty = PassageDifficulty.medium,
    this.masteryThreshold = 1.0,
    List<RetentionInterval>? retentionIntervals,
    this.readingTimerEnabled = true,
    this.recallTimerEnabled = true,
    this.soundEnabled = true,
    this.requireExactPunctuation = false,
    this.showCorrectionsImmediately = true,
    this.autoAdvance = false,
    this.fontScale = 1.0,
    this.hasSeenOnboarding = false,
    this.hasCompletedBaseline = false,
  }) : retentionIntervals = retentionIntervals ?? List.of(RetentionInterval.values);

  Map<String, dynamic> toJson() => {
        'defaultPassageLength': defaultPassageLength,
        'defaultDifficulty': defaultDifficulty.name,
        'masteryThreshold': masteryThreshold,
        'retentionIntervals': retentionIntervals.map((e) => e.name).toList(),
        'readingTimerEnabled': readingTimerEnabled,
        'recallTimerEnabled': recallTimerEnabled,
        'soundEnabled': soundEnabled,
        'requireExactPunctuation': requireExactPunctuation,
        'showCorrectionsImmediately': showCorrectionsImmediately,
        'autoAdvance': autoAdvance,
        'fontScale': fontScale,
        'hasSeenOnboarding': hasSeenOnboarding,
        'hasCompletedBaseline': hasCompletedBaseline,
      };

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
        defaultPassageLength: json['defaultPassageLength'] as int? ?? 90,
        defaultDifficulty: PassageDifficultyX.fromName(json['defaultDifficulty'] as String? ?? 'medium'),
        masteryThreshold: (json['masteryThreshold'] as num?)?.toDouble() ?? 1.0,
        retentionIntervals: (json['retentionIntervals'] as List<dynamic>?)
                ?.map((e) => RetentionIntervalX.fromName(e as String))
                .toList() ??
            List.of(RetentionInterval.values),
        readingTimerEnabled: json['readingTimerEnabled'] as bool? ?? true,
        recallTimerEnabled: json['recallTimerEnabled'] as bool? ?? true,
        soundEnabled: json['soundEnabled'] as bool? ?? true,
        requireExactPunctuation: json['requireExactPunctuation'] as bool? ?? false,
        showCorrectionsImmediately: json['showCorrectionsImmediately'] as bool? ?? true,
        autoAdvance: json['autoAdvance'] as bool? ?? false,
        fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1.0,
        hasSeenOnboarding: json['hasSeenOnboarding'] as bool? ?? false,
        hasCompletedBaseline: json['hasCompletedBaseline'] as bool? ?? false,
      );
}
