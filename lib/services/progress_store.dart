import 'package:shared_preferences/shared_preferences.dart';

import '../models/chakma_letter.dart';

/// Remembers, per character, how often it was practiced and matched.
///
/// Backed by shared_preferences (the same tiny on-device store that
/// remembers onboarding), with two int keys per character glyph:
/// `progress_attempts_<glyph>` and `progress_matches_<glyph>`. Glyphs are
/// unique across all categories, so they make safe keys.
///
/// A character counts as "mastered" once it has been matched
/// [masteryTarget] times — enough to prove it wasn't a lucky accident,
/// small enough to feel reachable.
class ProgressStore {
  ProgressStore._(); // Not meant to be instantiated — all methods are static.

  static const masteryTarget = 3;

  static String _attemptsKey(String glyph) => 'progress_attempts_$glyph';
  static String _matchesKey(String glyph) => 'progress_matches_$glyph';

  /// Records one Check tap for [glyph]; counts it as a success too when
  /// [matched] is true.
  static Future<void> recordAttempt(String glyph,
      {required bool matched}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _attemptsKey(glyph), (prefs.getInt(_attemptsKey(glyph)) ?? 0) + 1);
    if (matched) {
      await prefs.setInt(
          _matchesKey(glyph), (prefs.getInt(_matchesKey(glyph)) ?? 0) + 1);
    }
  }

  /// How many successful matches [glyph] has so far.
  static Future<int> matchCount(String glyph) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_matchesKey(glyph)) ?? 0;
  }

  /// The subset of [letters] that reached [masteryTarget] matches.
  static Future<Set<String>> masteredGlyphs(List<ChakmaLetter> letters) async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final letter in letters)
        if ((prefs.getInt(_matchesKey(letter.glyph)) ?? 0) >= masteryTarget)
          letter.glyph,
    };
  }
}
