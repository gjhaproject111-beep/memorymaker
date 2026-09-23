import '../models/enums.dart';
import '../models/passage.dart';
import '../repositories/passage_repository.dart';
import '../repositories/session_repository.dart';

class PassageSelectionResult {
  final Passage? passage;
  final bool libraryExhausted;
  const PassageSelectionResult({this.passage, this.libraryExhausted = false});
}

/// Chooses the next passage for training, always preferring one the user
/// has never seen a session for (spec §11: "must continuously use unseen
/// passages... otherwise the application would only measure how well I
/// learned the same passage through repetition").
class PassageSelectorService {
  const PassageSelectorService(this._passages, this._sessions);

  final PassageRepository _passages;
  final SessionRepository _sessions;

  Future<PassageSelectionResult> pickNext({PassageDifficulty? preferredDifficulty}) async {
    final all = await _passages.loadAll();
    final used = await _sessions.usedPassageIds();
    final unseen = all.where((p) => !used.contains(p.id)).toList()..shuffle();
    if (unseen.isEmpty) {
      return const PassageSelectionResult(libraryExhausted: true);
    }
    if (preferredDifficulty != null) {
      final matching = unseen.where((p) => p.difficulty == preferredDifficulty).toList();
      if (matching.isNotEmpty) return PassageSelectionResult(passage: matching.first);
    }
    return PassageSelectionResult(passage: unseen.first);
  }

  /// Several unseen passages spanning different categories, for the
  /// personal-baseline flow (spec §14) — never the same passage twice.
  Future<List<Passage>> pickBaselineSet({int count = 5}) async {
    final all = await _passages.loadAll();
    final used = await _sessions.usedPassageIds();
    final unseen = all.where((p) => !used.contains(p.id)).toList()..shuffle();

    final picked = <Passage>[];
    final usedCategories = <PassageCategory>{};
    for (final p in unseen) {
      if (picked.length >= count) break;
      if (usedCategories.contains(p.category)) continue;
      picked.add(p);
      usedCategories.add(p.category);
    }
    for (final p in unseen) {
      if (picked.length >= count) break;
      if (!picked.contains(p)) picked.add(p);
    }
    return picked;
  }
}
