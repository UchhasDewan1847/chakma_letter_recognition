import 'chakma_letter.dart';

/// One practice category on the home screen (consonants, numbers, vowels).
///
/// Each category bundles the characters to practice with the ONNX model
/// and labels file that judge them, so screens don't need to know which
/// model they're talking to. Adding a future category is one more entry
/// in [practiceCategories] plus its two asset files.
class LetterCategory {
  const LetterCategory({
    required this.title,
    required this.itemNoun,
    required this.emblemGlyph,
    required this.letters,
    required this.modelAsset,
    required this.labelsAsset,
  });

  final String title;

  /// "letter" or "number" — dropped into UI copy like
  /// "Draw the letter first!".
  final String itemNoun;

  /// A sample glyph shown on the category's home-screen card.
  final String emblemGlyph;

  final List<ChakmaLetter> letters;
  final String modelAsset;
  final String labelsAsset;
}

const consonantsCategory = LetterCategory(
  title: 'Consonants',
  itemNoun: 'letter',
  emblemGlyph: '\u{11107}', // kaa
  letters: chakmaConsonants,
  modelAsset: 'assets/models/chakma_consonents_detector.onnx',
  labelsAsset: 'assets/class_labels_consonents.json',
);

const numbersCategory = LetterCategory(
  title: 'Numbers',
  itemNoun: 'number',
  emblemGlyph: '\u{11137}', // 1
  letters: chakmaNumbers,
  modelAsset: 'assets/models/chakma_digits_detector.onnx',
  labelsAsset: 'assets/class_labels_digits.json',
);

const vowelsCategory = LetterCategory(
  title: 'Vowels',
  itemNoun: 'letter',
  emblemGlyph: '\u{11104}', // i
  letters: chakmaVowels,
  modelAsset: 'assets/models/chakma_vowel_detector.onnx',
  labelsAsset: 'assets/class_labels_vowels.json',
);

/// The categories that are ready to practice today.
const practiceCategories = [consonantsCategory, numbersCategory, vowelsCategory];
