# Bundled ONNX models (the live versions)

Every model here ships in the APK and is paired with a labels JSON in
`assets/` — output index `i` maps to entry `i` of that model's own labels
file. The pairs are wired up in `lib/models/letter_category.dart`.

| Model | Labels | Category |
|-------|--------|----------|
| `chakma_consonents_detector.onnx` (v2) | `assets/class_labels_consonents.json` | Consonants |
| `chakma_digits_detector.onnx` (v2) | `assets/class_labels_digits.json` | Numbers |
| `chakma_vowel_detector.onnx` (v1) | `assets/class_labels_vowels.json` | Vowels |
| `self_chakmanet_mobile.onnx` (v0) | — | Broken (untrained weights), kept until the user decides to drop it |

Superseded versions live in `model_archive/` at the repo root (kept out
of `assets/` so they don't bloat the APK) — see its README for the full
version history, probe results, and how to roll back.

Before swapping in any new model, probe it in Python first — see the
"ML preprocessing contract" section in CLAUDE.md.
