import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ojha_phat_sigon/models/chakma_letter.dart';
import 'package:ojha_phat_sigon/services/class_label_map.dart';

void main() {
  // flutter test runs from the project root, so the asset is readable
  // directly from disk without a widget binding.
  final labels = (jsonDecode(
    File('assets/class_labels.json').readAsStringSync(),
  ) as List)
      .cast<String>();
  final numberLabels = (jsonDecode(
    File('assets/class_labels_numbers.json').readAsStringSync(),
  ) as List)
      .cast<String>();

  test('class_labels.json has 33 unique number-glyph labels', () {
    expect(labels.length, 33);
    expect(labels.toSet().length, 33);
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

  test('unsupportedLetterNames matches what the model actually lacks', () {
    final covered = labels.map(letterNameForLabel).toSet();
    final actuallyMissing = {
      for (final letter in chakmaLetters)
        if (!covered.contains(letter.name)) letter.name,
    };
    // If this fails after swapping the model/labels, update
    // unsupportedLetterNames in class_label_map.dart to match.
    expect(unsupportedLetterNames, actuallyMissing);
  });

  test('the grid shows exactly the letters the model knows', () {
    expect(practiceableLetters.length,
        chakmaLetters.length - unsupportedLetterNames.length);
    for (final letter in practiceableLetters) {
      expect(unsupportedLetterNames.contains(letter.name), isFalse);
    }
  });

  test('displayLabel shows glyph plus name', () {
    expect(displayLabel('1-𑄇'), '𑄇  kaa');
    expect(displayLabel('33-𑄃'), '𑄃  aa');
    expect(displayLabel('99-?'), '99-?');
  });

  test('number labels are exactly the ten digits, in model-index order', () {
    // Output index i of the number model maps to class_labels_numbers[i],
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
}
