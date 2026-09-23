import 'dart:math' as math;

import '../models/comparison_result.dart';
import '../models/enums.dart';

/// The verbatim comparison engine (spec section 28).
///
/// Approach: tokenize both texts into words, then compute a classic
/// Needleman–Wunsch / Wagner–Fischer *word-level* global alignment (edit
/// distance with unit costs for substitution/insertion/deletion). The
/// traceback yields, for every original word, whether it was reproduced
/// correctly, omitted, substituted, or swapped with its neighbor — which is
/// exactly the "token-level edit distance / sequence alignment" the spec
/// calls for, and is far more meaningful than a raw word-count diff.
///
/// "Order accuracy" is reported separately via the longest common
/// subsequence (LCS) between the two normalized token streams, since LCS
/// length is a clean, standard measure of how much of the original survives
/// in the right relative order, independent of the position-exact alignment
/// used for the other metrics.
///
/// Scope note (kept deliberately simple for V1): automatic "wrong order"
/// classification covers *adjacent* transpositions (e.g. "A B C" recalled
/// as "A C B") — the case the spec's own example describes. Reordering
/// spread further apart than neighboring words shows up as substitutions
/// rather than a dedicated order error; a fuller shuffle detector is a
/// reasonable V2 extension point, not a V1 requirement.
class TextComparisonService {
  const TextComparisonService();

  /// A word must differ by no more than roughly a third of its shorter
  /// length (and at least 1 character) to be treated as a spelling slip
  /// rather than a genuine substitution — e.g. "recieve" vs "receive".
  static const int _spellingLeniency = 3;

  List<String> tokenize(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const [];
    return trimmed.split(RegExp(r'\s+'));
  }

  String normalizeToken(String token, {bool exactPunctuation = false}) {
    var t = token.toLowerCase();
    if (!exactPunctuation) {
      t = t.replaceAll(RegExp(r"^[^a-z0-9']+|[^a-z0-9']+$"), '');
    }
    return t;
  }

  ComparisonResult compare(
    String originalText,
    String recalledText, {
    bool exactPunctuation = false,
  }) {
    final originalRaw = tokenize(originalText);
    final recalledRaw = tokenize(recalledText);
    final originalNorm = originalRaw
        .map((t) => normalizeToken(t, exactPunctuation: exactPunctuation))
        .toList(growable: false);
    final recalledNorm = recalledRaw
        .map((t) => normalizeToken(t, exactPunctuation: exactPunctuation))
        .toList(growable: false);

    final steps = _align(originalNorm, recalledNorm);
    final alignedTokens = _classify(steps, originalRaw, recalledRaw, originalNorm, recalledNorm);
    final lcsLength = _lcsLength(originalNorm, recalledNorm);

    var correct = 0;
    final missing = <String>[];
    final extra = <String>[];
    final substitutions = <WordPair>[];
    final spellingErrors = <WordPair>[];
    final orderErrors = <WordPair>[];

    for (final token in alignedTokens) {
      switch (token.errorType) {
        case null:
          correct++;
        case ErrorType.missing:
          missing.add(token.originalWord!);
        case ErrorType.extra:
          extra.add(token.recalledWord!);
        case ErrorType.substituted:
          substitutions.add(WordPair(token.originalWord!, token.recalledWord!));
        case ErrorType.spelling:
          spellingErrors.add(WordPair(token.originalWord!, token.recalledWord!));
        case ErrorType.order:
          orderErrors.add(WordPair(token.originalWord!, token.recalledWord!));
      }
    }

    return ComparisonResult(
      originalText: originalText,
      recalledText: recalledText,
      alignedTokens: alignedTokens,
      originalWordCount: originalRaw.length,
      recalledWordCount: recalledRaw.length,
      correctWordCount: correct,
      missingWords: missing,
      extraWords: extra,
      substitutions: substitutions,
      spellingErrors: spellingErrors,
      orderErrors: orderErrors,
      longestOrderedMatch: lcsLength,
    );
  }

  // ---------------------------------------------------------------------
  // Word-level global alignment (Wagner–Fischer / Needleman-Wunsch).
  // ---------------------------------------------------------------------

  List<_TraceStep> _align(List<String> a, List<String> b) {
    final n = a.length;
    final m = b.length;
    final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
    for (var i = 1; i <= n; i++) {
      dp[i][0] = i;
    }
    for (var j = 1; j <= m; j++) {
      dp[0][j] = j;
    }
    for (var i = 1; i <= n; i++) {
      for (var j = 1; j <= m; j++) {
        final subCost = a[i - 1] == b[j - 1] ? 0 : 1;
        final diag = dp[i - 1][j - 1] + subCost;
        final up = dp[i - 1][j] + 1;
        final left = dp[i][j - 1] + 1;
        dp[i][j] = math.min(diag, math.min(up, left));
      }
    }

    final steps = <_TraceStep>[];
    var i = n;
    var j = m;
    while (i > 0 || j > 0) {
      if (i > 0 && j > 0) {
        final subCost = a[i - 1] == b[j - 1] ? 0 : 1;
        if (dp[i][j] == dp[i - 1][j - 1] + subCost) {
          steps.add(_TraceStep(subCost == 0 ? _EditOp.match : _EditOp.substitute, i - 1, j - 1));
          i--;
          j--;
          continue;
        }
      }
      if (i > 0 && dp[i][j] == dp[i - 1][j] + 1) {
        steps.add(_TraceStep(_EditOp.delete, i - 1, -1));
        i--;
        continue;
      }
      steps.add(_TraceStep(_EditOp.insert, -1, j - 1));
      j--;
    }
    return steps.reversed.toList(growable: false);
  }

  List<AlignedToken> _classify(
    List<_TraceStep> steps,
    List<String> originalRaw,
    List<String> recalledRaw,
    List<String> originalNorm,
    List<String> recalledNorm,
  ) {
    final result = <AlignedToken>[];
    var k = 0;
    while (k < steps.length) {
      final step = steps[k];
      switch (step.op) {
        case _EditOp.match:
          result.add(AlignedToken(
            originalWord: originalRaw[step.originalIndex],
            recalledWord: recalledRaw[step.recalledIndex],
            originalIndex: step.originalIndex,
            recalledIndex: step.recalledIndex,
          ));
          k++;

        case _EditOp.substitute:
          final swapConsumed = _tryClassifyAdjacentSwap(
            steps,
            k,
            originalRaw,
            recalledRaw,
            originalNorm,
            recalledNorm,
            result,
          );
          if (swapConsumed) {
            k += 2;
            continue;
          }
          final origWord = originalNorm[step.originalIndex];
          final recalledWord = recalledNorm[step.recalledIndex];
          final isSpelling = _isLikelySpelling(origWord, recalledWord);
          result.add(AlignedToken(
            originalWord: originalRaw[step.originalIndex],
            recalledWord: recalledRaw[step.recalledIndex],
            errorType: isSpelling ? ErrorType.spelling : ErrorType.substituted,
            originalIndex: step.originalIndex,
            recalledIndex: step.recalledIndex,
          ));
          k++;

        case _EditOp.delete:
          result.add(AlignedToken(
            originalWord: originalRaw[step.originalIndex],
            errorType: ErrorType.missing,
            originalIndex: step.originalIndex,
          ));
          k++;

        case _EditOp.insert:
          result.add(AlignedToken(
            recalledWord: recalledRaw[step.recalledIndex],
            errorType: ErrorType.extra,
            recalledIndex: step.recalledIndex,
          ));
          k++;
      }
    }
    return result;
  }

  /// If `steps[k]` and `steps[k+1]` are two adjacent substitutions that are
  /// really a transposition of two neighboring original words, appends two
  /// `ErrorType.order` tokens to [out] and returns true.
  bool _tryClassifyAdjacentSwap(
    List<_TraceStep> steps,
    int k,
    List<String> originalRaw,
    List<String> recalledRaw,
    List<String> originalNorm,
    List<String> recalledNorm,
    List<AlignedToken> out,
  ) {
    if (k + 1 >= steps.length || steps[k + 1].op != _EditOp.substitute) return false;
    final first = steps[k];
    final second = steps[k + 1];
    final ai = first.originalIndex, bj = first.recalledIndex;
    final ai2 = second.originalIndex, bj2 = second.recalledIndex;
    if (ai2 != ai + 1 || bj2 != bj + 1) return false;
    if (originalNorm[ai] != recalledNorm[bj2] || originalNorm[ai2] != recalledNorm[bj]) {
      return false;
    }
    out.add(AlignedToken(
      originalWord: originalRaw[ai],
      recalledWord: recalledRaw[bj],
      errorType: ErrorType.order,
      originalIndex: ai,
      recalledIndex: bj,
    ));
    out.add(AlignedToken(
      originalWord: originalRaw[ai2],
      recalledWord: recalledRaw[bj2],
      errorType: ErrorType.order,
      originalIndex: ai2,
      recalledIndex: bj2,
    ));
    return true;
  }

  bool _isLikelySpelling(String a, String b) {
    if (a.isEmpty || b.isEmpty || a == b) return false;
    final distance = _levenshtein(a, b);
    final shorter = math.min(a.length, b.length);
    final threshold = math.max(1, shorter ~/ _spellingLeniency);
    return distance <= threshold;
  }

  int _levenshtein(String a, String b) {
    final n = a.length;
    final m = b.length;
    final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
    for (var i = 0; i <= n; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j <= m; j++) {
      dp[0][j] = j;
    }
    for (var i = 1; i <= n; i++) {
      for (var j = 1; j <= m; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = math.min(dp[i - 1][j] + 1, math.min(dp[i][j - 1] + 1, dp[i - 1][j - 1] + cost));
      }
    }
    return dp[n][m];
  }

  int _lcsLength(List<String> a, List<String> b) {
    final n = a.length;
    final m = b.length;
    final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
    for (var i = 1; i <= n; i++) {
      for (var j = 1; j <= m; j++) {
        dp[i][j] =
            a[i - 1] == b[j - 1] ? dp[i - 1][j - 1] + 1 : math.max(dp[i - 1][j], dp[i][j - 1]);
      }
    }
    return dp[n][m];
  }
}

enum _EditOp { match, substitute, insert, delete }

class _TraceStep {
  final _EditOp op;
  final int originalIndex; // -1 for a pure insertion
  final int recalledIndex; // -1 for a pure deletion
  const _TraceStep(this.op, this.originalIndex, this.recalledIndex);
}
