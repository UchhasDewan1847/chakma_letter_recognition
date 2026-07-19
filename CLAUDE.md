# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Ojha Paath Sigi (displayed name; the Dart package, applicationId and repo folder keep the older `ojha_phat_sigon` spelling — renaming those would break imports and the install identity) is a Flutter app (Android + iOS) for learning to handwrite the Chakma script. The user picks a Chakma letter, draws it on a canvas, and an ONNX image-classification model judges whether the drawing matches. The user is a Flutter apprentice — explain non-obvious Flutter concepts when making changes.


## Commands

- `flutter run` — run on a connected device/emulator
- `flutter analyze` — static analysis (keep at zero issues)
- `flutter test` — run all widget tests
- `flutter test test/widget_test.dart` — run a single test file
- `./build_apk.sh` — release APK, copied to `build/OjhaPaathSigi-v<version>.apk` (don't rename inside Gradle; the Flutter tool requires the default `app-release.apk` name)
- `flutter pub run flutter_launcher_icons` — regenerate launcher icons from `assets/images/logo/app_icon*.png` (config in `flutter_launcher_icons.yaml`; use `flutter pub run`, not `dart run` — the standalone `dart` on PATH is older than Flutter's)

## Architecture

Screen flow: `WelcomeScreen` (onboarding PageView over the full village illustration, text on a dark bottom gradient) → `HomeScreen` (motivational header + one card per category: Consonants, Numbers, Vowels) → `LetterSelectScreen` (grid for the chosen category) → `PracticeScreen` (draw + check). A "Free draw" FAB on `LetterSelectScreen` opens `FreeDrawScreen` (no target; shows the closest class for whatever is drawn, judged by that category's model).

Onboarding is first-launch-only: `main()` reads the `seen_onboarding` bool from `shared_preferences` and starts on `HomeScreen` when set; `WelcomeScreen._finish` writes it (key constant `seenOnboardingPrefsKey` lives in `welcome_screen.dart`). The permanent instructions live in `InstructionsScreen` (`lib/screens/instructions_screen.dart`), one long scrollable English how-to page opened from the paper icon at the top right of `HomeScreen`. Result feedback is deliberately number-free: `PracticeScreen` grades phrases on match + confidence (≥0.75 "clearly matches"; miss but target in top-3 → "So close!"), and `FreeDrawScreen` shows confidence words ("quite sure"/"not fully sure"/"only guessing") instead of percentages.

`PracticeScreen` has three modes (`PracticeMode` enum: Trace/Copy/Memory, SegmentedButton under the target card). Trace overlays the glyph in 30 % grey on the board — deliberately *outside* the DrawingBoard's RepaintBoundary, inside an IgnorePointer, so the model snapshot stays clean white and touches pass through. Memory hides the sample behind "?" until the card is held (peek). A match fires `ConfettiBurst` (`lib/widgets/confetti_burst.dart`, dependency-free one-shot CustomPainter) plus a haptic buzz.

Progress: `lib/services/progress_store.dart` counts attempts/matches per glyph in shared_preferences (glyphs are unique across categories, so they're the keys); `masteryTarget` = 3 matches earns the star. `PracticeScreen` records on every check; `LetterSelectScreen` shows stars and `HomeScreen` shows "X of N mastered" bars — both reload after `await Navigator.push(...)` returns so fresh stars appear immediately.

Noto Sans Chakma (41 KB, SIL OFL) is bundled in `assets/fonts/` and applied in `main.dart` as `fontFamilyFallback` on the theme's text themes: Latin text keeps the default font, Chakma codepoints fall through to Noto, so glyphs render on devices without a Chakma system font.

Model versioning: superseded model+labels pairs live in `model_archive/` at the repo root — intentionally outside `assets/` so they stay in git without shipping in the APK. Its README has the version map, probe history, and the roll-back procedure. `assets/models/README.md` maps the live pairs.

All screens after onboarding sit on `AppBackground` (`lib/widgets/app_background.dart`): the pre-blurred illustration + a translucent surface wash, with the screen's Scaffold and AppBar made transparent. The blur is baked into the asset (no runtime BackdropFilter) — regenerate both background jpgs from `potentialBackGround3.jpg` with PIL if the artwork changes (downscale for welcome; downscale + GaussianBlur 18 for the app-wide one). The drawing board is unaffected: it paints its own solid white inside its RepaintBoundary, so model input stays white.

- `lib/models/letter_category.dart` — `LetterCategory` bundles a category's title, characters, and its own model + labels assets; `practiceCategories` lists the three live ones (consonants, numbers, vowels). Screens receive a category and never hardcode a model. Adding a category = one entry here + two asset files.
- `lib/models/chakma_letter.dart` — defines `ChakmaLetter` (Unicode glyph + romanized name like "kaa") and the lists `chakmaVowels` (𑄃𑄄𑄅𑄆, U+11103–U+11106), `chakmaConsonants` (32 letters, U+11107–U+11126) and `chakmaNumbers` (digits 0–9, U+11136–U+1113F, named "0".."9"); `chakmaLetters` is vowels + consonants concatenated, used for glyph→name lookup. Each category's grid shows its own list — 𑄃 ("aa") lives only in the Vowels grid even though the consonant model also has an "aa" class.
- `lib/widgets/drawing_board.dart` — `DrawingController` (ChangeNotifier holding strokes; owns undo/clear) is deliberately separate from the `DrawingBoard` widget so screens own drawing state. The board is wrapped in a `RepaintBoundary` whose GlobalKey lets `PracticeScreen` snapshot the canvas as an image for inference.
- `lib/services/letter_recognizer.dart` — constructed with a category's model/labels assets, loads them via `onnxruntime`, preprocesses the snapshot, runs inference, returns top-3 `Prediction`s.
- `lib/services/class_label_map.dart` — translates model labels into character names. Consonant labels look like `"1-𑄇"` (dataset class number, dash, glyph); number and vowel labels are bare glyphs like `"𑄶"`/`"𑄃"`. The glyph part joins directly to `chakmaLetters`/`chakmaNumbers`. Screens display labels through `displayLabel()` ("𑄇  kaa", "𑄶  0"), and `PracticeScreen` counts a match when the predicted label's name equals the target's name. `test/class_label_map_test.dart` checks every JSON label resolves, that each model's label order matches its grid list, and pins the consonant model's one extra class ("aa") — if a retrained model breaks that test, revisit which grid each letter belongs to.

### ML preprocessing contract (verified empirically, do not change)

All three models are MobileNetV2 with the same pipeline: resize to 224×224 (bilinear) → RGB → scale to 0–1 → **ImageNet normalization** ((x − mean)/std with mean [0.485, 0.456, 0.406], std [0.229, 0.224, 0.225]) → channel-first `[1, 3, 224, 224]`.
- Consonants (`chakma_consonents_detector.onnx`, 32 classes → `class_labels_consonents.json[i]`): probed 2026-07-19 (`probe_new_models.py` pattern), 32/32 top-1 on font-rendered glyphs with ImageNet norm (0.96 mean conf) vs 25/32 with plain 0–1; shape-sensitive. Replaced `mobilenetv2_mobile.onnx` — the old 33rd "aa" (𑄃) class is gone, so model classes now match the consonant grid exactly.
- Numbers (`chakma_digits_detector.onnx`, 10 classes → `class_labels_digits.json[i]`): probed 2026-07-19, 8/10 top-1 with ImageNet norm (0.92 mean conf, best regime); shape-sensitive. On font renders 𑄸 "2" and 𑄽 "7" drift to 𑄺 "4" — same weak spots as the `chakma_number_detector.onnx` it replaced (label order unchanged).
- Vowels (`chakma_vowel_detector.onnx`, 4 classes → `class_labels_vowels.json[i]`): probed 2026-07-15, shape-sensitive. Font-render accuracy is 3/4 in *every* regime (ImageNet, 0–1, ×2−1) — 𑄅 "u" is the weak class, drifting to 𑄃/𑄆 — so the regime probe couldn't discriminate; ImageNet norm was kept because it matches the sibling models and gave the highest correct-class confidence (0.88 mean vs 0.76). If users report 𑄅 never matching, suspect the model, not the pipeline.

If a model is ever swapped, re-probe before assuming the same contract (shape-sensitivity first: blank vs circle vs cross logits must differ meaningfully).

### Known open items

- The vowel model is weak on 𑄅 "u" (see contract above); if practice for it frustrates users, it needs retraining.
- The digit model's font-render misses (𑄸 "2", 𑄽 "7" → 𑄺 "4") may or may not show up on real handwriting; if users report those digits never matching, suspect the model.
- `assets/models/self_chakmanet_mobile.onnx` is the superseded broken model, still bundled (~1.2 MB of APK weight); the user wants old models kept for backtracking — if it ever moves, it belongs in `model_archive/`, not the bin.
- `LetterRecognizer.load()` returns an error string the UI shows, so the app must keep working when the model file is absent.

## Assets

- `assets/images/background.jpg` — welcome-screen artwork (from `potentialBackGround3.jpg`, downscaled); plain colour fallback if missing
- `assets/images/background_blurred.jpg` — pre-blurred app-wide background (13 KB)
- `assets/images/potentialbackground1.jpg` / `potentialBackGround3.jpg` — the user's original artwork candidates; they ship in the APK (~0.9 MB) because the whole images/ dir is a registered asset — move them out of assets/ if APK size matters
- `assets/images/logo/logo-1rst.png` — the logo shown on `HomeScreen` (icon fallback if missing)
- `assets/models/chakma_consonents_detector.onnx` — consonant classifier (9 MB)
- `assets/models/chakma_digits_detector.onnx` — number classifier (8.9 MB)
- `assets/models/chakma_vowel_detector.onnx` — vowel classifier (8.9 MB)
- `assets/class_labels_consonents.json` — consonant index → label list (32 labels, `"number-glyph"` form)
- `assets/class_labels_digits.json` — number index → label list (10 bare glyphs, 𑄶–𑄿 in 0–9 order)
- `assets/class_labels_vowels.json` — vowel index → label list (4 bare glyphs, 𑄃𑄄𑄅𑄆 in aa/i/u/e order)
- all three label JSONs are registered individually in pubspec.yaml
- `assets/fonts/NotoSansChakma-Regular.ttf` — bundled Chakma font (registered under `fonts:` in pubspec, not `assets:`)
- `model_archive/` (repo root, NOT an asset) — superseded model+labels version pairs; see its README
