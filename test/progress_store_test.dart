import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ojha_phat_sigon/models/chakma_letter.dart';
import 'package:ojha_phat_sigon/services/progress_store.dart';

void main() {
  // shared_preferences talks to the OS through a platform channel; this
  // swaps in an in-memory fake so the tests need no device.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final kaa = chakmaConsonants.first; // 𑄇 "kaa"

  test('a character is mastered after masteryTarget matches', () async {
    for (var i = 0; i < ProgressStore.masteryTarget; i++) {
      expect(await ProgressStore.masteredGlyphs(chakmaConsonants), isEmpty,
          reason: 'not mastered before match ${i + 1}');
      await ProgressStore.recordAttempt(kaa.glyph, matched: true);
    }

    expect(await ProgressStore.masteredGlyphs(chakmaConsonants), {kaa.glyph});
    expect(await ProgressStore.matchCount(kaa.glyph),
        ProgressStore.masteryTarget);
  });

  test('failed attempts never count towards mastery', () async {
    for (var i = 0; i < ProgressStore.masteryTarget * 2; i++) {
      await ProgressStore.recordAttempt(kaa.glyph, matched: false);
    }

    expect(await ProgressStore.matchCount(kaa.glyph), 0);
    expect(await ProgressStore.masteredGlyphs(chakmaConsonants), isEmpty);
  });

  test('mastery is tracked per character', () async {
    final khaa = chakmaConsonants[1];
    for (var i = 0; i < ProgressStore.masteryTarget; i++) {
      await ProgressStore.recordAttempt(kaa.glyph, matched: true);
    }
    await ProgressStore.recordAttempt(khaa.glyph, matched: true);

    expect(await ProgressStore.masteredGlyphs(chakmaConsonants), {kaa.glyph});
  });
}
