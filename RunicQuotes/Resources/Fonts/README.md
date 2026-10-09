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

### Runatal Cirth
- **Style:** Cirth graph shapes; Angerthas Erebor sound assignment in the app
- **Internal PostScript name:** `RunatalCirth-Regular`
- **Coverage:** CSUR core Cirth U+E080–U+E0C1 and ordinary ASCII punctuation
- **License:** SIL Open Font License 1.1, [bundled license](RunatalCirth-OFL.txt)
- **Source:** [Kurinto 2.197 Lite](https://kurinto.com/zip/Kurinto_v2.197_Lite.zip), `Fonts_Aux/KurintoMonoAux-Rg.ttf`
- **Original SHA256:** `88ef1ab8d15c642aef58f2ccfa0968e23428b4f19faf664a9817ae57d39052b1`
- **Derivative:** Cirth + ASCII subset renamed to respect the reserved font name Kurinto; copyright and OFL retained.
- **Encoding:** [CSUR registry](https://www.evertype.com/standards/csur/cirth.html). Code points identify shapes; the [Appendix E table](https://mirrors.mit.edu/CTAN/fonts/cirth/cirth.pdf) distinguishes Moria and Erebor sounds.
- **File:** `RunatalCirth-Regular.ttf`

## Registration

Fonts are registered via `UIAppFonts` in both app and widget `Info.plist` (configured in `project.yml`). Target membership is handled automatically by XcodeGen.

## Troubleshooting

If fonts render as boxes:
1. Verify `.ttf` files exist in this directory
2. Run `xcodegen generate`
3. Clean build (Cmd+Shift+K) and rebuild
