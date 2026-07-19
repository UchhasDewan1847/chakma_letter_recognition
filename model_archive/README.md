# Model archive

Superseded model + label pairs, kept so any version can be restored.
Each version folder holds the `.onnx` **and** the matching labels JSON —
they are a pair and must always be swapped together (output index `i` of a
model maps to entry `i` of *its own* labels file).

This folder is intentionally **outside `assets/`**: registered asset
directories are bundled into the APK, and archived models would add
~18 MB for every user. Here they live only in the git repo.

## Version map

| Category   | Version | Model | Labels | Classes | Status |
|------------|---------|-------|--------|---------|--------|
| Consonants | v0 | `assets/models/self_chakmanet_mobile.onnx` | used consonants v1 labels | 33 | **Broken** (exported without trained weights) — still bundled in the APK until the user decides to drop it |
| Consonants | v1 | `consonants_v1/mobilenetv2_mobile.onnx` | `consonants_v1/class_labels.json` | 33 (incl. extra "aa" 𑄃) | Archived 2026-07-19. Probed 28/33 top-1, ImageNet norm |
| Consonants | **v2 (live)** | `assets/models/chakma_consonents_detector.onnx` | `assets/class_labels_consonents.json` | 32 (no "aa") | Probed 32/32 top-1, ImageNet norm |
| Digits | v1 | `digits_v1/chakma_number_detector.onnx` | `digits_v1/class_labels_numbers.json` | 10 | Archived 2026-07-19. Probed 8/10 top-1, ImageNet norm |
| Digits | **v2 (live)** | `assets/models/chakma_digits_detector.onnx` | `assets/class_labels_digits.json` | 10 (same label order as v1) | Probed 8/10 top-1 (weak: 𑄸 "2", 𑄽 "7"), ImageNet norm |
| Vowels | **v1 (live)** | `assets/models/chakma_vowel_detector.onnx` | `assets/class_labels_vowels.json` | 4 | Probed 3/4 (weak: 𑄅 "u"), ImageNet norm |

All probed versions follow the same preprocessing contract (see the "ML
preprocessing contract" section in CLAUDE.md): 224×224 bilinear → RGB →
0–1 → ImageNet mean/std → `[1, 3, 224, 224]` channel-first.

## How to roll back to an archived version (e.g. consonants v1)

1. Copy the pair back into assets:
   `cp model_archive/consonants_v1/mobilenetv2_mobile.onnx assets/models/`
   `cp model_archive/consonants_v1/class_labels.json assets/`
2. Register the labels file in `pubspec.yaml` under `assets:`
   (the `.onnx` is covered by the `assets/models/` directory entry).
3. Point the category at the pair in `lib/models/letter_category.dart`
   (`modelAsset` / `labelsAsset` of `consonantsCategory`).
4. Consonants only: v1 has the extra 33rd "aa" class —
   `test/class_label_map_test.dart` expects 32 classes and no extras, so
   flip those expectations back (`labels.length` 33, `extras` `{'aa'}`).
5. Run `flutter analyze && flutter test`.
