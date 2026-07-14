/// One Chakma character the user can practice (letter or digit).
///
/// [glyph] is the actual Unicode character (Chakma block U+11100–U+1114F).
/// If a device's system font can't render Chakma, the letter will show as a
/// box (tofu) — we can bundle the Noto Sans Chakma font later to fix that.
class ChakmaLetter {
  const ChakmaLetter(this.glyph, this.name);

  final String glyph;
  final String name; // romanized name, e.g. "kaa" — or "7" for a digit
}

/// The basic Chakma alphabet: independent vowels first, then consonants.
const chakmaLetters = [
  ChakmaLetter('\u{11103}', 'aa'),
  ChakmaLetter('\u{11104}', 'i'),
  ChakmaLetter('\u{11105}', 'u'),
  ChakmaLetter('\u{11106}', 'e'),
  ChakmaLetter('\u{11107}', 'kaa'),
  ChakmaLetter('\u{11108}', 'khaa'),
  ChakmaLetter('\u{11109}', 'gaa'),
  ChakmaLetter('\u{1110A}', 'ghaa'),
  ChakmaLetter('\u{1110B}', 'ngaa'),
  ChakmaLetter('\u{1110C}', 'caa'),
  ChakmaLetter('\u{1110D}', 'chaa'),
  ChakmaLetter('\u{1110E}', 'jaa'),
  ChakmaLetter('\u{1110F}', 'jhaa'),
  ChakmaLetter('\u{11110}', 'nyaa'),
  ChakmaLetter('\u{11111}', 'ttaa'),
  ChakmaLetter('\u{11112}', 'tthaa'),
  ChakmaLetter('\u{11113}', 'ddaa'),
  ChakmaLetter('\u{11114}', 'ddhaa'),
  ChakmaLetter('\u{11115}', 'nnaa'),
  ChakmaLetter('\u{11116}', 'taa'),
  ChakmaLetter('\u{11117}', 'thaa'),
  ChakmaLetter('\u{11118}', 'daa'),
  ChakmaLetter('\u{11119}', 'dhaa'),
  ChakmaLetter('\u{1111A}', 'naa'),
  ChakmaLetter('\u{1111B}', 'paa'),
  ChakmaLetter('\u{1111C}', 'phaa'),
  ChakmaLetter('\u{1111D}', 'baa'),
  ChakmaLetter('\u{1111E}', 'bhaa'),
  ChakmaLetter('\u{1111F}', 'maa'),
  ChakmaLetter('\u{11120}', 'yyaa'),
  ChakmaLetter('\u{11121}', 'yaa'),
  ChakmaLetter('\u{11122}', 'raa'),
  ChakmaLetter('\u{11123}', 'laa'),
  ChakmaLetter('\u{11124}', 'waa'),
  ChakmaLetter('\u{11125}', 'saa'),
  ChakmaLetter('\u{11126}', 'haa'),
];

/// The Chakma digits 0–9 (U+11136–U+1113F), named by their numeric value.
const chakmaNumbers = [
  ChakmaLetter('\u{11136}', '0'),
  ChakmaLetter('\u{11137}', '1'),
  ChakmaLetter('\u{11138}', '2'),
  ChakmaLetter('\u{11139}', '3'),
  ChakmaLetter('\u{1113A}', '4'),
  ChakmaLetter('\u{1113B}', '5'),
  ChakmaLetter('\u{1113C}', '6'),
  ChakmaLetter('\u{1113D}', '7'),
  ChakmaLetter('\u{1113E}', '8'),
  ChakmaLetter('\u{1113F}', '9'),
];
