# Bundled fonts

- `NotoSansChakma-Regular.ttf` — Google's Noto Sans Chakma, bundled so
  Chakma glyphs render on devices without a Chakma system font. Applied
  app-wide as a *fallback* family in `main.dart`: Latin text keeps the
  default Roboto look, and only Chakma codepoints fall through to Noto.

Noto fonts are licensed under the SIL Open Font License 1.1
(https://openfontlicense.org) — free to bundle and redistribute with the
app, including commercially; the font itself may not be sold on its own.
