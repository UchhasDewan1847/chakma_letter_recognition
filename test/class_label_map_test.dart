import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ojha_phat_sigon/models/chakma_letter.dart';
import 'package:ojha_phat_sigon/services/class_label_map.dart';

void main() {
  // flutter test runs from the project root, so the asset is readable
  // directly from disk without a widget binding.
  final labels = (jsonDecode(
    File('assets/class_labels_consonents.json').readAsStringSync(),
  ) as List)
      .cast<String>();
  final numberLabels = (jsonDecode(
    File('assets/class_labels_digits.json').readAsStringSync(),
  ) as List)
      .cast<String>();
  final vowelLabels = (jsonDecode(
    File('assets/class_labels_vowels.json').readAsStringSync(),
  ) as List)
      .cast<String>();

  test('the alphabet is the 4 vowels plus the 32 consonants', () {
    expect(chakmaVowels.length, 4);
    expect(chakmaConsonants.length, 32);
    expect(chakmaLetters.length, 36);
  });

  test('consonant labels are 32 unique number-glyph entries', () {
    expect(labels.length, 32);
    expect(labels.toSet().length, 32);
    for (final label in labels) {
      expect(RegExp(r'^\d+-.+$').hasMatch(label), isTrue,
          reason: 'label "$label" is not in "number-glyph" form');
    }
  });

  test('every model label resolves to a letter name', () {
    for (final label in labels) {
      expect(letterNameForLabel(label), isNotNull,
          reason: 'label "$label" has no name — displayLabel would show '
              'the raw label and it could never match a practice letter');
    }
  });

  test('the consonant model covers every letter in the consonant grid', () {
    final covered = labels.map(letterNameForLabel).toSet();
    for (final letter in chakmaConsonants) {
      expect(covered.contains(letter.name), isTrue,
          reason: '"${letter.name}" is in the grid but the model was not '
              'trained on it — practicing it could never succeed');
    }
    // The retrained model dropped the old 33rd "aa" (𑄃) class, so the
    // model's classes and the consonant grid now match exactly. If a
    // future retrain adds classes, revisit which grid each letter
    // belongs to.
    final extras = covered.difference(
      {for (final letter in chakmaConsonants) letter.name},
    );
    expect(extras, isEmpty);
  });

  test('displayLabel shows glyph plus name', () {
    expect(displayLabel('1-𑄇'), '𑄇  kaa');
    expect(displayLabel('99-?'), '99-?');
  });

  test('number labels are exactly the ten digits, in model-index order', () {
    // Output index i of the digit model maps to class_labels_digits[i],
    // which must line up with the digits the grid offers.
    expect(numberLabels, [for (final n in chakmaNumbers) n.glyph]);
  });

  test('every number label resolves and displays with its digit', () {
    for (final label in numberLabels) {
      expect(letterNameForLabel(label), matches(RegExp(r'^\d$')),
          reason: 'number label "$label" should map to a single digit name');
    }
    expect(displayLabel('𑄶'), '𑄶  0');
    expect(displayLabel('𑄿'), '𑄿  9');
  });

  test('vowel labels are exactly the four vowels, in model-index order', () {
    // Output index i of the vowel model maps to class_labels_vowels[i],
    // which must line up with the vowels the grid offers.
    expect(vowelLabels, [for (final v in chakmaVowels) v.glyph]);
  });

  test('every vowel label resolves and displays with its name', () {
    for (final label in vowelLabels) {
      expect(letterNameForLabel(label), isNotNull,
          reason: 'vowel label "$label" has no name');
    }
    expect(displayLabel('𑄃'), '𑄃  aa');
    expect(displayLabel('𑄆'), '𑄆  e');
  });
}
