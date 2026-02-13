# Runic Fonts

Custom runic fonts bundled with the app and widget.

## Fonts

### Noto Sans Runic
- **Style:** Modern, clean
- **Coverage:** Elder Futhark, Younger Futhark (Unicode U+16A0-U+16EA)
- **License:** Open Font License (OFL)
- **Source:** [Google Fonts](https://fonts.google.com/noto/specimen/Noto+Sans+Runic)
- **File:** `NotoSansRunic-Regular.ttf`

### BabelStone Runic
- **Style:** Historical, comprehensive
- **Coverage:** Elder Futhark, Younger Futhark, Anglo-Saxon, Medieval
- **License:** Free for personal and commercial use
- **Source:** [BabelStone](https://www.babelstone.co.uk/Fonts/index.html)
- **File:** `BabelStoneRunic.ttf`

### Cirth Angerthas
- **Style:** Tolkien's Elvish runes
- **Internal font name:** `Angerthas Moria` (used in `.custom()` calls)
- **Coverage:** Latin-substitution font; rune glyphs at ASCII positions (a-z, A-Z) plus Latin-1 supplement (thorn, eth, ntilde, ccedilla) for digraph sounds
- **Source:** [dafont](https://www.dafont.com/angerthas-erebor.font)
- **File:** `CirthAngerthas.ttf`

## Registration

Fonts are registered via `UIAppFonts` in both app and widget `Info.plist` (configured in `project.yml`). Target membership is handled automatically by XcodeGen.

## Troubleshooting

If fonts render as boxes:
1. Verify `.ttf` files exist in this directory
2. Run `xcodegen generate`
3. Clean build (Cmd+Shift+K) and rebuild
