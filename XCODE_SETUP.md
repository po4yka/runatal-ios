# Xcode Setup

## Prerequisites

- Xcode 15+ with iOS 17 SDK
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Quick Start

```bash
xcodegen generate
open RunicQuotes.xcodeproj
```

Select a simulator (iPhone 16 recommended) and press Cmd+R.

## What XcodeGen Handles

The `project.yml` configures everything automatically:

- **Targets:** `RunicQuotes` (app), `RunicQuotesWidget` (extension), test targets
- **Font registration:** `UIAppFonts` in both app and widget Info.plist
- **App Groups:** `group.com.po4yka.runicquotes` for shared data
- **Source discovery:** All `.swift` files under `RunicQuotes/` are included automatically
- **Resource bundling:** Fonts, seed data, assets, localization files

New `.swift` files are picked up automatically. Just regenerate the project if you add new resource types or change targets.

## Regenerating

After modifying `project.yml`:

```bash
xcodegen generate
```

The `.xcodeproj` is gitignored -- always regenerate from `project.yml`.

## Troubleshooting

### Fonts show as boxes

1. Verify `.ttf` files exist in `RunicQuotes/Resources/Fonts/`
2. Run `xcodegen generate` to ensure fonts are registered
3. Clean build: Cmd+Shift+K, then rebuild

### SwiftData errors

1. Confirm deployment target is iOS 17.0+ in `project.yml`
2. Check `@Model` macro on `Quote` and `UserPreferences`
3. Clean and rebuild

### Seed data not loading

1. Verify `quotes.json` exists in `RunicQuotes/Resources/SeedData/`
2. Ensure `project.yml` includes `SeedData` in resources

### Widget not building

1. Run `xcodegen generate` to regenerate both targets
2. Verify `RunicQuotesWidget/` directory exists with source files
3. Check that shared model files are under `RunicQuotes/Models/` (auto-included by widget target)
