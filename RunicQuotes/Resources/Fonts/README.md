# Runic Fonts

This folder contains the custom runic fonts used in the Runic Quotes app.

## Required Fonts

### 1. Noto Sans Runic (Modern, Clean)

**Download:**
- Google Fonts: https://fonts.google.com/noto/specimen/Noto+Sans+Runic
- Direct GitHub: https://github.com/notofonts/runic/releases

**File:** `NotoSansRunic-Regular.ttf`

**License:** Open Font License (OFL) - Free for commercial use ✅

---

### 2. BabelStone Runic (Historical, Comprehensive)

**Download:**
- BabelStone Fonts: https://www.babelstone.co.uk/Fonts/index.html
- Direct Download: https://www.babelstone.co.uk/Fonts/Download/BabelStoneRunic.ttf

**File:** `BabelStoneRunic.ttf`

**License:** Free for personal and commercial use ✅

**Coverage:** Elder Futhark, Younger Futhark, Anglo-Saxon Futhorc, Medieval runes

---

### 3. Cirth / Angerthas Font (Tolkien's Elvish Runes)

**Recommended Options:**

**Option A: Cirth Erebor**
- Source: https://www.dafont.com/angerthas-erebor.font
- File: Rename to `CirthAngerthas.ttf`

**Option B: Tengwar Annatar** (includes Cirth)
- Source: http://www.acondia.com/fonts/tengwar/
- Alternative: https://freetengwar.sourceforge.net/

**File:** `CirthAngerthas.ttf` (rename after download for consistency)

**License:** Verify for commercial use (most are free for personal use)

**Note:** Uses Private Use Area (PUA) codepoints - requires custom mapping in `CirthMap.swift`

---

## Installation Instructions

1. **Download all three fonts** using the links above
2. **Place the font files** in this directory (`RunicQuotes/Resources/Fonts/`)
3. **Verify file names:**
   - `NotoSansRunic-Regular.ttf`
   - `BabelStoneRunic.ttf`
   - `CirthAngerthas.ttf`

4. **Add to Xcode project:**
   - Drag font files into Xcode project navigator
   - Check **Target Membership** for:
     - ✅ RunicQuotes (main app)
     - ✅ RunicQuotesWidget (widget extension)

5. **Update Info.plist** (both app and widget):
   ```xml
   <key>UIAppFonts</key>
   <array>
       <string>NotoSansRunic-Regular.ttf</string>
       <string>BabelStoneRunic.ttf</string>
       <string>CirthAngerthas.ttf</string>
   </array>
   ```

6. **Verify font names** in code:
   ```swift
   // List all available fonts
   for family in UIFont.familyNames.sorted() {
       print("Family: \(family)")
       for font in UIFont.fontNames(forFamilyName: family) {
           print("  - \(font)")
       }
   }
   ```

## Expected Font Names (for code)

- `"Noto Sans Runic"`
- `"BabelStone Runic"`
- `"[Your Cirth Font Name]"` (depends on font chosen)

## Unicode Ranges

- **Elder Futhark:** U+16A0–U+16EA
- **Younger Futhark:** U+16A0–U+16EA (subset)
- **Cirth:** Private Use Area (font-specific, typically U+E000+)

## Notes

- All fonts must support the required Unicode ranges
- Fonts must be added to both app and widget targets
- Widget Info.plist must also include UIAppFonts array
- Test font rendering in simulator and on device

## Troubleshooting

If fonts don't appear:
1. Verify file names match exactly (case-sensitive)
2. Check Target Membership in Xcode
3. Ensure Info.plist entries are correct
4. Clean build folder (Cmd+Shift+K) and rebuild
5. Check internal font name with UIFont.familyNames

---

**Last Updated:** 2025-11-15
