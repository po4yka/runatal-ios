# Xcode Project Setup Guide

This guide will help you create the Xcode project for the Runic Quotes iOS app.

## Prerequisites

- macOS with Xcode 15.0 or later
- iOS 17.0+ SDK
- Basic familiarity with Xcode

## Step 1: Create the Xcode Project

1. **Open Xcode**
2. **File → New → Project**
3. Select **iOS → App**
4. Click **Next**

### Project Configuration:

- **Product Name:** `RunicQuotes`
- **Team:** Select your development team
- **Organization Identifier:** `com.po4yka`
- **Bundle Identifier:** `com.po4yka.runicquotes`
- **Interface:** **SwiftUI**
- **Language:** **Swift**
- **Storage:** **SwiftData** ✓
- **Include Tests:** ✓ (checked)

5. Click **Next**
6. Choose the location: **Navigate to this repository folder** (`runatal-ios`)
7. Click **Create**

⚠️ **IMPORTANT:** When prompted to "Create Git repository", select **NO** (we already have one)

## Step 2: Delete Default Files

Xcode will create some default files we don't need:

1. In the Project Navigator, **delete** these files:
   - `RunicQuotesApp.swift` (we have our own in `App/`)
   - `ContentView.swift` (we have our own in `App/RunicQuotesApp.swift`)
   - `Item.swift` (sample SwiftData model)

2. When prompted, select **Move to Trash**

## Step 3: Add Source Files to Xcode

Now add all the source files we created:

1. **Right-click** on the `RunicQuotes` group (folder) in Xcode
2. Select **Add Files to "RunicQuotes"...**
3. Navigate to `RunicQuotes/` folder in Finder
4. Select **ALL** the folders:
   - `App/`
   - `Models/`
   - `Data/`
   - `ViewModels/`
   - `Views/`
   - `Resources/`
   - `Utilities/`

5. **Important checkboxes:**
   - ✓ **Copy items if needed** (UNCHECKED - files are already in place)
   - ✓ **Create groups** (SELECTED)
   - ✓ **Add to targets:** RunicQuotes (CHECKED)

6. Click **Add**

## Step 4: Configure Font Files

The fonts are already in `RunicQuotes/Resources/Fonts/`, but we need to ensure Xcode knows about them:

1. In Project Navigator, navigate to `RunicQuotes/Resources/Fonts/`
2. Select each `.ttf` file:
   - `NotoSansRunic-Regular.ttf`
   - `BabelStoneRunic.ttf`
   - `CirthAngerthas.ttf`

3. In the **File Inspector** (right panel), under **Target Membership:**
   - ✓ **RunicQuotes** (checked)

## Step 5: Verify Info.plist

1. In Project Navigator, open `RunicQuotes/App/Info.plist`
2. Verify it contains the `UIAppFonts` array with our three fonts
3. If not visible, check the **project settings**:
   - Select the **RunicQuotes** project (top of navigator)
   - Select the **RunicQuotes** target
   - Go to **Info** tab
   - Under **Custom iOS Target Properties**, verify `UIAppFonts` is present

## Step 6: Configure Build Settings

### Minimum Deployment Target

1. Select **RunicQuotes** project
2. Select **RunicQuotes** target
3. **General** tab
4. Set **Minimum Deployments → iOS:** `17.0`

### Swift Language Version

1. **Build Settings** tab
2. Search for "Swift Language Version"
3. Ensure it's set to **Swift 5** or later

### Code Signing

1. **Signing & Capabilities** tab
2. Select your **Team**
3. Xcode will automatically manage signing

## Step 7: Add Resource Bundle

We need to ensure the JSON seed data is accessible:

1. In Project Navigator, select `quotes.json` in `Resources/SeedData/`
2. In **File Inspector**, verify **Target Membership:**
   - ✓ **RunicQuotes** (checked)

## Step 8: Build the Project

1. Select a simulator or device (iPhone 15 Pro recommended)
2. Press **Cmd + B** to build
3. Fix any build errors (see Troubleshooting below)

## Step 9: Run the App

1. Press **Cmd + R** to run
2. The app should launch and display a quote in runic script!

## Expected Result

You should see:
- A black/grayscale liquid glass background
- A quote displayed in Elder Futhark runes (using Noto Sans Runic font)
- The Latin translation below
- Author attribution
- A "Next Quote" button
- "Phase 1 Complete ✓" at the bottom

## Troubleshooting

### Fonts Not Rendering

**Problem:** Runic text shows as boxes or missing glyphs

**Solution:**
1. Verify fonts are in `Resources/Fonts/` folder
2. Check **File Inspector** → **Target Membership** for each `.ttf` file
3. Verify `Info.plist` has `UIAppFonts` array
4. Clean build folder: **Product → Clean Build Folder** (Cmd + Shift + K)
5. Rebuild: **Product → Build** (Cmd + B)

### Seed Data Not Loading

**Problem:** Error message "Could not find seed data file"

**Solution:**
1. Verify `quotes.json` is in `Resources/SeedData/`
2. Check **Target Membership** for `quotes.json`
3. In code, the path should be: `Bundle.main.url(forResource: "quotes", withExtension: "json", subdirectory: "Resources/SeedData")`

### SwiftData Errors

**Problem:** "Failed to create ModelContainer" error

**Solution:**
1. Verify all model files are included in the target
2. Check that `@Model` macro is properly applied to `Quote` and `UserPreferences`
3. Ensure iOS deployment target is 17.0+

### Missing Imports

**Problem:** "No such module 'SwiftData'" or similar errors

**Solution:**
1. Verify iOS deployment target is 17.0+ (SwiftData requires iOS 17+)
2. Clean and rebuild

## Verification Checklist

Before moving to Phase 2, verify:

- [ ] Project builds without errors
- [ ] App launches on simulator/device
- [ ] Fonts render correctly (you see actual runes, not boxes)
- [ ] Database seeds with 40 quotes (check console logs)
- [ ] "Quote of the Day" loads and displays
- [ ] "Next Quote" button fetches a random quote
- [ ] Runic transliteration displays properly
- [ ] Author and Latin text display correctly
- [ ] No console errors or warnings

## Next Steps

Once Phase 1 is complete and verified:
- **Phase 2:** Core App UI (ViewModels, glass components, settings)
- **Phase 3:** Widgets (Home Screen and Lock Screen)
- **Phase 4:** Testing & Quality
- **Phase 5:** Polish & Finalization
- **Phase 6:** Release

## Additional Configuration (Optional)

### SwiftLint

If you want to add code linting:

```bash
brew install swiftlint
```

Then create `.swiftlint.yml` in the project root (already provided).

### SwiftFormat

For code formatting:

```bash
brew install swiftformat
```

---

**Questions or Issues?**

Refer to the main README or create an issue in the repository.

**Phase 1 Status:** ✅ Foundation Complete
