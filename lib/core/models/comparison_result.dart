import 'enums.dart';

/// One slot in the word-level alignment between the original passage and
/// the user's recall. Either [originalWord] or [recalledWord] (never both)
/// is null for an insertion/deletion slot.
class AlignedToken {
  final String? originalWord;
  final String? recalledWord;
  final ErrorType? errorType; // null means an exact correct match
  final int? originalIndex;
  final int? recalledIndex;

  const AlignedToken({
    this.originalWord,
    this.recalledWord,
    this.errorType,
    this.originalIndex,
    this.recalledIndex,
  });

  bool get isCorrect => errorType == null;
}

class WordPair {
  final String original;
  final String recalled;
  const WordPair(this.original, this.recalled);
}

/// The full, structured output of comparing one recall attempt against the
/// original passage. Every rate is expressed against [originalWordCount] so
/// the metrics stay comparable across passages of different lengths.
class ComparisonResult {
  final String originalText;
  final String recalledText;
  final List<AlignedToken> alignedTokens;

  final int originalWordCount;
  final int recalledWordCount;
  final int correctWordCount;

  final List<String> missingWords;
  final List<String> extraWords;
  final List<WordPair> substitutions;
  final List<WordPair> spellingErrors;
  final List<WordPair> orderErrors; // (expectedWord, recalledInItsPlace)

  const ComparisonResult({
    required this.originalText,
    required this.recalledText,
    required this.alignedTokens,
    required this.originalWordCount,
    required this.recalledWordCount,
    required this.correctWordCount,
    required this.missingWords,
    required this.extraWords,
    required this.substitutions,
    required this.spellingErrors,
    required this.orderErrors,
    required this.longestOrderedMatch,
  });

  final int longestOrderedMatch; // LCS length, used for orderAccuracy

  double get exactWordAccuracy =>
      originalWordCount == 0 ? 0 : correctWordCount / originalWordCount;

  double get orderAccuracy =>
      originalWordCount == 0 ? 0 : longestOrderedMatch / originalWordCount;

  double get omissionRate =>
      originalWordCount == 0 ? 0 : missingWords.length / originalWordCount;

  double get substitutionRate =>
      originalWordCount == 0 ? 0 : substitutions.length / originalWordCount;

  double get extraWordRate =>
      originalWordCount == 0 ? 0 : extraWords.length / originalWordCount;

  double get spellingErrorRate =>
      originalWordCount == 0 ? 0 : spellingErrors.length / originalWordCount;

  bool isMastery(double threshold) => exactWordAccuracy >= threshold;
}
