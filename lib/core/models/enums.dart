/// Shared enums for the training domain, plus small string<->enum helpers
/// used by the hand-written JSON (de)serialization in each model.

enum PassageCategory { general, science, history, education, nature, technology }

extension PassageCategoryX on PassageCategory {
  String get label {
    switch (this) {
      case PassageCategory.general:
        return 'General';
      case PassageCategory.science:
        return 'Science';
      case PassageCategory.history:
        return 'History';
      case PassageCategory.education:
        return 'Education';
      case PassageCategory.nature:
        return 'Nature';
      case PassageCategory.technology:
        return 'Technology';
    }
  }

  static PassageCategory fromName(String name) =>
      PassageCategory.values.firstWhere((e) => e.name == name, orElse: () => PassageCategory.general);
}

enum PassageDifficulty { easy, medium, hard, advanced }

extension PassageDifficultyX on PassageDifficulty {
  String get label {
    switch (this) {
      case PassageDifficulty.easy:
        return 'Easy';
      case PassageDifficulty.medium:
        return 'Medium';
      case PassageDifficulty.hard:
        return 'Hard';
      case PassageDifficulty.advanced:
        return 'Advanced';
    }
  }

  static PassageDifficulty fromName(String name) =>
      PassageDifficulty.values.firstWhere((e) => e.name == name, orElse: () => PassageDifficulty.medium);
}

/// The five error categories the comparison engine can assign to a token.
enum ErrorType { missing, extra, substituted, order, spelling }

extension ErrorTypeX on ErrorType {
  String get label {
    switch (this) {
      case ErrorType.missing:
        return 'Missing';
      case ErrorType.extra:
        return 'Extra';
      case ErrorType.substituted:
        return 'Substituted';
      case ErrorType.order:
        return 'Wrong order';
      case ErrorType.spelling:
        return 'Spelling';
    }
  }

  static ErrorType fromName(String name) =>
      ErrorType.values.firstWhere((e) => e.name == name, orElse: () => ErrorType.substituted);
}

enum SessionStatus { inProgress, mastered, abandoned }

extension SessionStatusX on SessionStatus {
  static SessionStatus fromName(String name) =>
      SessionStatus.values.firstWhere((e) => e.name == name, orElse: () => SessionStatus.inProgress);
}

/// A configurable delayed-retention checkpoint, in minutes from mastery.
enum RetentionInterval { tenMinutes, oneDay, threeDays, sevenDays, thirtyDays }

extension RetentionIntervalX on RetentionInterval {
  int get minutesFromMastery {
    switch (this) {
      case RetentionInterval.tenMinutes:
        return 10;
      case RetentionInterval.oneDay:
        return 24 * 60;
      case RetentionInterval.threeDays:
        return 3 * 24 * 60;
      case RetentionInterval.sevenDays:
        return 7 * 24 * 60;
      case RetentionInterval.thirtyDays:
        return 30 * 24 * 60;
    }
  }

  String get label {
    switch (this) {
      case RetentionInterval.tenMinutes:
        return '10 Minutes';
      case RetentionInterval.oneDay:
        return '24 Hours';
      case RetentionInterval.threeDays:
        return '3 Days';
      case RetentionInterval.sevenDays:
        return '7 Days';
      case RetentionInterval.thirtyDays:
        return '30 Days';
    }
  }

  static RetentionInterval fromName(String name) => RetentionInterval.values
      .firstWhere((e) => e.name == name, orElse: () => RetentionInterval.tenMinutes);
}
