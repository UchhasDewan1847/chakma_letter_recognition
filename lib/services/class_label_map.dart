import '../models/chakma_letter.dart';

/// Translates the models' class labels into character names.
///
/// The consonant model's `assets/class_labels_consonents.json` holds
/// labels like "1-𑄇": the training dataset's class number, a dash, then
/// the Chakma glyph. The digit and vowel models' label files hold bare
/// glyphs like "𑄶" or "𑄃". Either way the glyph part is looked up
/// directly in `chakmaLetters` / `chakmaNumbers` to get its name.
/// test/class_label_map_test.dart pins that each model's classes match
/// its grid exactly.

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
