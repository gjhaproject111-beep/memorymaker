import 'package:flutter_test/flutter_test.dart';
import 'package:photographic_memory/core/models/enums.dart';
import 'package:photographic_memory/core/services/text_comparison_service.dart';

void main() {
  final engine = const TextComparisonService();

  group('TextComparisonService', () {
    test('1. Perfect recall scores 100% and has no errors', () {
      const original = 'The ancient civilization developed complex systems of agriculture.';
      final result = engine.compare(original, original);
      expect(result.exactWordAccuracy, 1.0);
      expect(result.orderAccuracy, 1.0);
      expect(result.missingWords, isEmpty);
      expect(result.extraWords, isEmpty);
      expect(result.substitutions, isEmpty);
      expect(result.orderErrors, isEmpty);
      expect(result.spellingErrors, isEmpty);
    });

    test('2. A single missing word is detected as an omission', () {
      const original = 'The quick brown fox jumps over the lazy dog';
      const recalled = 'The quick brown fox over the lazy dog';
      final result = engine.compare(original, recalled);
      expect(result.missingWords, contains('jumps'));
      expect(result.missingWords.length, 1);
      expect(result.substitutions, isEmpty);
    });

    test('3. A single extra word is detected as an insertion', () {
      const original = 'The quick brown fox jumps over the lazy dog';
      const recalled = 'The quick brown red fox jumps over the lazy dog';
      final result = engine.compare(original, recalled);
      expect(result.extraWords, contains('red'));
      expect(result.extraWords.length, 1);
    });

    test('4. A substituted word is detected, not scored as correct', () {
      const original = 'The ancient civilization developed complex systems of agriculture along the river.';
      const recalled = 'The ancient civilization developed sophisticated systems of agriculture along the river.';
      final result = engine.compare(original, recalled);
      final hasExpectedSubstitution =
          result.substitutions.any((p) => p.original == 'complex' && p.recalled == 'sophisticated');
      expect(hasExpectedSubstitution, isTrue);
      expect(result.exactWordAccuracy, lessThan(1.0));
    });

    test('5. Two textually-adjacent swapped words are classified as order errors, not substitutions', () {
      // "quickly" and "chased" are immediate neighbors in the original and
      // appear swapped, immediately adjacent, in the recall.
      const original = 'The cat quickly chased the mouse';
      const recalled = 'The cat chased quickly the mouse';
      final result = engine.compare(original, recalled);
      expect(result.orderErrors.length, 2);
      expect(result.substitutions, isEmpty);
      expect(result.missingWords, isEmpty);
      expect(result.extraWords, isEmpty);
      // Every original word is present, but not all in the exact aligned
      // sequence, so order accuracy is stricter than a simple presence check.
      expect(result.orderAccuracy, lessThan(1.0));
    });

    test('6. Multiple simultaneous error types are all captured independently', () {
      // Two words dropped with nothing in their place (unambiguous deletion),
      // one substitution paired against one leftover extra (forced, since the
      // recalled segment there has one more token than the original one), and
      // one extra word with nothing on the original side (unambiguous
      // insertion). Anchored by unique surrounding words so the DP cannot
      // trade errors across segments.
      const original =
          'The rapid growth of technology has fundamentally transformed how people communicate today across the globe.';
      const recalled =
          'The rapid growth of technology transformed how people constantly converse today loudly across the globe.';
      final result = engine.compare(original, recalled);
      expect(result.missingWords.toSet(), {'has', 'fundamentally'});
      expect(result.substitutions.length, 1);
      expect(result.extraWords.length, 2);
      expect(result.exactWordAccuracy, lessThan(1.0));
    });

    test('7. Punctuation differences are not scored as errors by default', () {
      const original = 'Hello, world! This is a test.';
      const recalled = 'Hello world This is a test';
      final result = engine.compare(original, recalled);
      expect(result.exactWordAccuracy, 1.0);
    });

    test('7b. Punctuation differences ARE scored when exactPunctuation is on', () {
      const original = 'Hello, world!';
      const recalled = 'Hello world';
      final result = engine.compare(original, recalled, exactPunctuation: true);
      expect(result.exactWordAccuracy, lessThan(1.0));
    });

    test('8. Capitalization differences are never scored as errors', () {
      const original = 'The Ancient Civilization Was Remarkable';
      const recalled = 'the ancient civilization was remarkable';
      final result = engine.compare(original, recalled);
      expect(result.exactWordAccuracy, 1.0);
    });

    test('9. Repeated words in the original are each tracked independently', () {
      const original = 'run run run away';
      const recalled = 'run run away';
      final result = engine.compare(original, recalled);
      expect(result.missingWords.length, 1);
      expect(result.missingWords.first, 'run');
    });

    test('10. Similar (near-miss spelling) words are classified as spelling errors', () {
      const original = 'I would like to receive the package tomorrow';
      const recalled = 'I would like to recieve the package tomorrow';
      final result = engine.compare(original, recalled);
      expect(result.spellingErrors, isNotEmpty);
      expect(result.substitutions, isEmpty);
    });

    test('11. An empty recall is all missing words, zero accuracy', () {
      const original = 'This passage was never attempted at all';
      const recalled = '';
      final result = engine.compare(original, recalled);
      expect(result.exactWordAccuracy, 0.0);
      expect(result.missingWords.length, result.originalWordCount);
      expect(result.recalledWordCount, 0);
    });

    test('12. A very long recall still resolves without error and stays bounded', () {
      final original = List.filled(300, 'word').join(' ');
      final recalled = List.filled(500, 'word').join(' ');
      final result = engine.compare(original, recalled);
      expect(result.originalWordCount, 300);
      expect(result.recalledWordCount, 500);
      expect(result.extraWords.length, 200);
      expect(result.exactWordAccuracy, 1.0); // all 300 original words matched in order
    });

    test('Comparison is deterministic across repeated runs', () {
      const original = 'The mitochondria is the powerhouse of the cell';
      const recalled = 'The mitochondria are the power house of cell';
      final first = engine.compare(original, recalled);
      final second = engine.compare(original, recalled);
      expect(first.exactWordAccuracy, second.exactWordAccuracy);
      expect(first.missingWords, second.missingWords);
      expect(first.substitutions.length, second.substitutions.length);
    });

    test('Mastery threshold check', () {
      const original = 'Perfect recall of this exact sentence';
      final result = engine.compare(original, original);
      expect(result.isMastery(1.0), isTrue);
      expect(result.isMastery(0.5), isTrue);
      const partial = 'Perfect recall of this exact';
      final partialResult = engine.compare(original, partial);
      expect(partialResult.isMastery(1.0), isFalse);
    });
  });
}
