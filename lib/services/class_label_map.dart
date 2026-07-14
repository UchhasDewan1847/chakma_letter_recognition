import '../models/chakma_letter.dart';

/// Translates the models' class labels into character names.
///
/// The consonant model's `assets/class_labels.json` holds labels like
/// "1-𑄇": the training dataset's class number, a dash, then the Chakma
/// glyph. The number model's `assets/class_labels_numbers.json` holds
/// bare glyphs like "𑄶". Either way the glyph part is looked up directly
/// in `chakmaLetters` / `chakmaNumbers` to get its name.

/// Letters that exist in the alphabet but NOT in the current 33-class
/// model (it covers the 32 consonants plus "aa"). These are hidden from
/// the letter grid: practicing them could never report a correct match.
/// If the model is retrained with these classes, remove them from here —
/// test/class_label_map_test.dart fails if this set drifts out of sync
/// with assets/class_labels.json.
const unsupportedLetterNames = {'i', 'u', 'e'};

/// The letters shown in the grid: only ones the model can recognize.
final List<ChakmaLetter> practiceableLetters = [
  for (final letter in chakmaLetters)
    if (!unsupportedLetterNames.contains(letter.name)) letter,
];

/// The glyph part of a raw label ("1-𑄇" -> "𑄇").
String _glyphOfLabel(String rawLabel) {
  final dash = rawLabel.indexOf('-');
  return dash == -1 ? rawLabel : rawLabel.substring(dash + 1);
}

final Map<String, String> _glyphToName = {
  for (final letter in chakmaLetters) letter.glyph: letter.name,
  for (final number in chakmaNumbers) number.glyph: number.name,
};

/// The letter name for a raw model label, or null if unknown.
String? letterNameForLabel(String rawLabel) =>
    _glyphToName[_glyphOfLabel(rawLabel)];

/// What to show the user for a raw model label: glyph plus name
/// (e.g. "𑄇  kaa") when known, otherwise the raw label itself.
String displayLabel(String rawLabel) {
  final glyph = _glyphOfLabel(rawLabel);
  final name = _glyphToName[glyph];
  return name == null ? rawLabel : '$glyph  $name';
}
