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

Screen flow: `WelcomeScreen` (onboarding PageView over the full village illustration, text on a dark bottom gradient) → `HomeScreen` (motivational header + one card per category: Consonants, Numbers, and a disabled "Vowels — coming soon" teaser) → `LetterSelectScreen` (grid for the chosen category) → `PracticeScreen` (draw + check). A "Free draw" FAB on `LetterSelectScreen` opens `FreeDrawScreen` (no target; shows the closest class for whatever is drawn, judged by that category's model).

All screens after onboarding sit on `AppBackground` (`lib/widgets/app_background.dart`): the pre-blurred illustration + a translucent surface wash, with the screen's Scaffold and AppBar made transparent. The blur is baked into the asset (no runtime BackdropFilter) — regenerate both background jpgs from `potentialBackGround3.jpg` with PIL if the artwork changes (downscale for welcome; downscale + GaussianBlur 18 for the app-wide one). The drawing board is unaffected: it paints its own solid white inside its RepaintBoundary, so model input stays white.

- `lib/models/letter_category.dart` — `LetterCategory` bundles a category's title, characters, and its own model + labels assets; `practiceCategories` lists the ready ones. Screens receive a category and never hardcode a model. Adding the future vowel category = one entry here + two asset files.
- `lib/models/chakma_letter.dart` — defines `ChakmaLetter` (Unicode glyph + romanized name like "kaa") and two lists: `chakmaLetters` (36 letters, U+11103–U+11126) and `chakmaNumbers` (digits 0–9, U+11136–U+1113F, named "0".."9"). The consonant grid shows `practiceableLetters` (from `class_label_map.dart`): `chakmaLetters` minus `unsupportedLetterNames`, the letters the current model wasn't trained on.
- `lib/widgets/drawing_board.dart` — `DrawingController` (ChangeNotifier holding strokes; owns undo/clear) is deliberately separate from the `DrawingBoard` widget so screens own drawing state. The board is wrapped in a `RepaintBoundary` whose GlobalKey lets `PracticeScreen` snapshot the canvas as an image for inference.
- `lib/services/letter_recognizer.dart` — constructed with a category's model/labels assets, loads them via `onnxruntime`, preprocesses the snapshot, runs inference, returns top-3 `Prediction`s.
- `lib/services/class_label_map.dart` — translates model labels into character names. Consonant labels look like `"1-𑄇"` (dataset class number, dash, glyph); number labels are bare glyphs like `"𑄶"`. The glyph part joins directly to `chakmaLetters`/`chakmaNumbers`. Screens display labels through `displayLabel()` ("𑄇  kaa", "𑄶  0"), and `PracticeScreen` counts a match when the predicted label's name equals the target's name. `test/class_label_map_test.dart` checks every JSON label resolves and documents the coverage gap below.

### ML preprocessing contract (verified empirically, do not change)

Both models are MobileNetV2 with the same pipeline: resize to 224×224 (bilinear) → RGB → scale to 0–1 → **ImageNet normalization** ((x − mean)/std with mean [0.485, 0.456, 0.406], std [0.229, 0.224, 0.225]) → channel-first `[1, 3, 224, 224]`.
- Consonants (`mobilenetv2_mobile.onnx`, 33 classes → `class_labels.json[i]`): probed 2026-07-13, 28/33 top-1 on font-rendered glyphs with ImageNet norm vs 5/33 with plain 0–1.
- Numbers (`chakma_number_detector.onnx`, 10 classes → `class_labels_numbers.json[i]`): probed 2026-07-14 (`probe_numbers.py` pattern), 8/10 top-1 with ImageNet norm vs 2/10 with plain 0–1; shape-sensitive (blank/circle/cross logits differ), so genuinely trained.

If a model is ever swapped, re-probe before assuming the same contract (shape-sensitivity first: blank vs circle vs cross logits must differ meaningfully).

### Known open items

- The 33-class consonant model covers the 32 consonants + "aa" only; i (𑄄), u (𑄅), e (𑄆) are hidden from the grid via `unsupportedLetterNames` in `class_label_map.dart`. If the model is retrained with those classes, empty that set — a test fails if it drifts out of sync with `class_labels.json`.
- A 4-letter vowel model is planned. When it arrives: probe it in Python first, add a `vowelsCategory` to `letter_category.dart`, replace the disabled teaser card in `home_screen.dart`, and reconsider `unsupportedLetterNames`/the "aa" overlap between categories.
- `assets/models/self_chakmanet_mobile.onnx` is the superseded broken model, still bundled (~1.2 MB of APK weight); safe to delete once the user confirms.
- `LetterRecognizer.load()` returns an error string the UI shows, so the app must keep working when the model file is absent.
- Chakma glyphs render via system fonts; on devices without Chakma support they show as boxes — the fix is bundling Noto Sans Chakma (see `assets/letters/README.md`).

## Assets

- `assets/images/background.jpg` — welcome-screen artwork (from `potentialBackGround3.jpg`, downscaled); plain colour fallback if missing
- `assets/images/background_blurred.jpg` — pre-blurred app-wide background (13 KB)
- `assets/images/potentialbackground1.jpg` / `potentialBackGround3.jpg` — the user's original artwork candidates; they ship in the APK (~0.9 MB) because the whole images/ dir is a registered asset — move them out of assets/ if APK size matters
- `assets/images/logo/logo-1rst.png` — the logo shown on `HomeScreen` (icon fallback if missing)
- `assets/models/mobilenetv2_mobile.onnx` — consonant classifier (9 MB)
- `assets/models/chakma_number_detector.onnx` — number classifier (8.9 MB)
- `assets/class_labels.json` — consonant index → label list (33 labels, `"number-glyph"` form)
- `assets/class_labels_numbers.json` — number index → label list (10 bare glyphs, 𑄶–𑄿 in 0–9 order)
- both label JSONs are registered individually in pubspec.yaml
