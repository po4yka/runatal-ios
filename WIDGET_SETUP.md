# Widget Extension Setup Guide

This guide will help you add the WidgetKit extension to the Runic Quotes iOS app.

## Prerequisites

- Xcode 15.0 or later
- iOS 17.0+ SDK
- Main app project already created (see XCODE_SETUP.md)

## Step 1: Create Widget Extension Target

1. **Open your Xcode project**
2. **File → New → Target**
3. Select **iOS → Widget Extension**
4. Click **Next**

### Extension Configuration:

- **Product Name:** `RunicQuotesWidget`
- **Team:** Select your development team
- **Organization Identifier:** `com.po4yka`
- **Bundle Identifier:** `com.po4yka.runicquotes.RunicQuotesWidget`
- **Project:** RunicQuotes
- **Embed in Application:** RunicQuotes ✓
- **Include Configuration Intent:** ❌ (Unchecked)

5. Click **Finish**
6. When prompted "Activate 'RunicQuotesWidget' scheme?", click **Cancel** (we'll use the main app scheme)

## Step 2: Delete Default Widget Files

Xcode creates default widget files we don't need:

1. In Project Navigator, expand the **RunicQuotesWidget** group
2. **Delete** these files:
   - `RunicQuotesWidget.swift` (we have our own)
   - `RunicQuotesWidgetBundle.swift` (merged into our RunicQuoteWidget.swift)
   - `RunicQuotesWidget.intentdefinition` (not using Intents)
   - `AppIntent.swift` (not using App Intents)

3. Select **Move to Trash**

## Step 3: Add Widget Source Files

1. **Right-click** on the `RunicQuotesWidget` group in Xcode
2. Select **Add Files to "RunicQuotes"...**
3. Navigate to the `RunicQuotesWidget/` folder
4. Select **ALL** the folders:
   - `Models/`
   - `Provider/`
   - `Views/`
   - `RunicQuoteWidget.swift`
   - `Info.plist`

5. **Important checkboxes:**
   - ❌ **Copy items if needed** (UNCHECKED - files already in place)
   - ✓ **Create groups** (SELECTED)
   - ✓ **Add to targets:** RunicQuotesWidget (CHECKED)
   - ❌ **Add to targets:** RunicQuotes (UNCHECKED)

6. Click **Add**

## Step 4: Share Model Files with Widget

The widget needs access to the main app's models. Add target membership:

1. **Select each model file** in Project Navigator:
   - `RunicQuotes/Models/Quote.swift`
   - `RunicQuotes/Models/UserPreferences.swift`
   - `RunicQuotes/Models/Enums/RunicScript.swift`
   - `RunicQuotes/Models/Enums/RunicFont.swift`
   - `RunicQuotes/Models/Enums/WidgetMode.swift`

2. In **File Inspector** (right panel), under **Target Membership:**
   - ✓ **RunicQuotes** (checked)
   - ✓ **RunicQuotesWidget** (check this too)

3. **Also share these files:**
   - `RunicQuotes/Data/Repositories/QuoteRepository.swift`
   - `RunicQuotes/Data/Transliteration/RunicTransliterator.swift`
   - `RunicQuotes/Data/Transliteration/ElderFutharkMap.swift`
   - `RunicQuotes/Data/Transliteration/YoungerFutharkMap.swift`
   - `RunicQuotes/Data/Transliteration/CirthMap.swift`
   - `RunicQuotes/Utilities/Extensions/Color+Grayscale.swift`
   - `RunicQuotes/Utilities/RunicFontConfiguration.swift`

4. Add target membership to **both** RunicQuotes and RunicQuotesWidget

## Step 5: Share Font Files with Widget

Widgets need access to the custom fonts:

1. **Select each font file** in `RunicQuotes/Resources/Fonts/`:
   - `NotoSansRunic-Regular.ttf`
   - `BabelStoneRunic.ttf`
   - `CirthAngerthas.ttf`

2. In **File Inspector**, under **Target Membership:**
   - ✓ **RunicQuotes** (should already be checked)
   - ✓ **RunicQuotesWidget** (check this too)

## Step 6: Share Seed Data with Widget

The widget needs access to the quotes database:

1. **Select** `RunicQuotes/Resources/SeedData/quotes.json`
2. In **File Inspector**, under **Target Membership:**
   - ✓ **RunicQuotes** (should already be checked)
   - ✓ **RunicQuotesWidget** (check this too)

## Step 7: Configure App Groups

Both the app and widget need to share data through an App Group:

### Main App Target:

1. Select **RunicQuotes** project (top of navigator)
2. Select **RunicQuotes** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Search for and add **App Groups**
6. Click **+** under App Groups
7. Enter: `group.com.po4yka.runicquotes`
8. Press Enter

### Widget Extension Target:

1. Select **RunicQuotesWidget** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Click **+** under App Groups
6. Enter: `group.com.po4yka.runicquotes` (same as main app)
7. Press Enter

⚠️ **IMPORTANT:** Both targets MUST use the exact same App Group identifier!

## Step 8: Verify Widget Info.plist

1. Select `RunicQuotesWidget/Info.plist`
2. Verify it contains:
   - `NSExtension` dictionary with `NSExtensionPointIdentifier` = `com.apple.widgetkit-extension`
   - `UIAppFonts` array with all three font files

## Step 9: Configure Widget Scheme (Optional)

To debug the widget:

1. Click the scheme dropdown (next to Run/Stop buttons)
2. Select **Edit Scheme...**
3. In the left sidebar, expand **Run**
4. Select **Info**
5. Change **Executable** to **Ask on Launch**
6. This lets you choose which widget size to debug

## Step 10: Build and Test

### Build Both Targets:

1. Select **RunicQuotes** scheme
2. Press **Cmd + B** to build
3. Fix any build errors

### Run on Simulator/Device:

1. Press **Cmd + R** to run the app
2. Once running:
   - **Long press** on the Home Screen
   - Tap **+** in the top-left corner
   - Search for "Runic Quote"
   - Select widget size (Small, Medium, or Large)
   - Tap **Add Widget**

### Test Lock Screen Widgets:

1. On device/simulator, go to **Lock Screen**
2. **Long press** on Lock Screen
3. Tap **Customize**
4. Tap on widget area below the clock
5. Search for "Runic Quote"
6. Add Circular, Rectangular, or Inline widget

## Expected Widget Behavior

### Home Screen Widgets:

- **Small:** Runic text only with script name
- **Medium:** Runic text + Latin translation + author
- **Large:** Full quote display with header and dividers

### Lock Screen Widgets:

- **Circular:** Single runic character
- **Rectangular:** Runic text + author (2 lines)
- **Inline:** Runic text only (single line)

### Widget Updates:

- **Daily mode:** Updates at midnight each day
- **Random mode:** Updates every hour
- **Tap widget:** Opens app to Quote tab

## Troubleshooting

### Fonts Not Rendering in Widget

**Problem:** Widget shows boxes instead of runic glyphs

**Solution:**
1. Verify fonts are in `RunicQuotes/Resources/Fonts/`
2. Check **Target Membership** includes **RunicQuotesWidget**
3. Verify `RunicQuotesWidget/Info.plist` has `UIAppFonts` array
4. Clean build: **Product → Clean Build Folder** (Cmd + Shift + K)
5. Rebuild and reinstall widget

### Widget Shows "Unable to Load"

**Problem:** Widget displays error message

**Solution:**
1. Check that **both** targets have the **same** App Group
2. Verify App Group format: `group.com.po4yka.runicquotes`
3. Ensure all shared files have widget target membership
4. Check console logs for error messages

### Widget Not Updating

**Problem:** Widget stuck on old quote

**Solution:**
1. Long press widget → **Remove Widget**
2. Re-add the widget
3. Or: Force quit app and widget:
   - Double-click Home button
   - Swipe up on app and widget
   - Re-launch

### Build Errors: "No such module"

**Problem:** Widget can't find models/utilities

**Solution:**
1. Verify **Target Membership** for all shared files
2. Check that models have both targets checked
3. Clean build folder and rebuild

### Deep Linking Not Working

**Problem:** Tapping widget doesn't open app

**Solution:**
1. Verify `runicquotes://` URL scheme in app's `Info.plist`
2. Check `CFBundleURLTypes` array is properly configured
3. Verify `onOpenURL` handler in `RunicQuotesApp.swift`
4. Test deep link manually: `xcrun simctl openurl booted runicquotes://quote`

## Verification Checklist

Before moving to Phase 4, verify:

- [ ] Widget extension target created
- [ ] All widget source files added to widget target
- [ ] Model files shared with widget (target membership)
- [ ] Fonts shared with widget (target membership)
- [ ] Seed data shared with widget (target membership)
- [ ] App Groups configured identically in both targets
- [ ] Widget builds without errors
- [ ] Small widget displays runic text
- [ ] Medium widget displays runic + Latin text
- [ ] Large widget displays full quote
- [ ] Lock Screen widgets display correctly
- [ ] Widgets update daily/hourly based on mode
- [ ] Tapping widget opens app to Quote tab
- [ ] No console errors when widget loads

## Next Steps

Once Phase 3 is complete and verified:
- **Phase 4:** Testing & Quality (Unit tests, UI tests, GitHub Actions CI/CD)
- **Phase 5:** Polish & Finalization (App icon, launch screen, accessibility)
- **Phase 6:** Release (App Store submission)

---

**Questions or Issues?**

- See `runic_quotes_i_os_readme.md` for the full roadmap
- Check widget source files for implementation details
- Test widgets on both simulator and device for best results

**Phase 3 Status:** ✅ Widgets Complete
