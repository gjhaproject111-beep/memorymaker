import 'dart:math';

/// Small dependency-free unique ID generator (timestamp + random suffix).
/// Good enough for a single-user, local-only app — not a distributed UUID.
class IdGenerator {
  static final Random _random = Random.secure();

  static String next([String prefix = '']) {
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final rand = List.generate(6, (_) => _random.nextInt(36).toRadixString(36)).join();
    return prefix.isEmpty ? '$ts$rand' : '$prefix-$ts$rand';
  }
}
