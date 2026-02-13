# Runic Quotes

iOS app that displays inspirational quotes rendered in ancient runic scripts: Elder Futhark, Younger Futhark, and Tolkien's Cirth. Features Home Screen and Lock Screen widgets, glassmorphism UI, and three bundled runic fonts.

## Tech Stack

- **Platform:** iOS 17+, Swift 6, SwiftUI
- **Data:** SwiftData
- **Widgets:** WidgetKit (Home Screen + Lock Screen)
- **Fonts:** Noto Sans Runic, BabelStone Runic, Cirth Angerthas
- **Build:** XcodeGen (`project.yml`)
- **Architecture:** MVVM with actors for concurrency

## Getting Started

```bash
# Generate Xcode project
xcodegen generate

# Open in Xcode
open RunicQuotes.xcodeproj

# Or build from CLI
xcodebuild -scheme RunicQuotes -destination 'platform=iOS Simulator,name=iPhone 16' build
```

See [XCODE_SETUP.md](XCODE_SETUP.md) for detailed setup and troubleshooting.

## Project Structure

```
RunicQuotes/
  App/              App entry point, Info.plist
  Models/           SwiftData models, enums (RunicScript, RunicFont, etc.)
  Data/             Repositories, transliteration engine, actors
  ViewModels/       QuoteViewModel, SettingsViewModel
  Views/            SwiftUI views and reusable components
  Utilities/        Haptics, theme palette, font config, extensions
  Resources/        Fonts, seed data, assets, localization

RunicQuotesWidget/  WidgetKit extension (timeline provider, views)
```

## Key Features

- **3 runic scripts** with real-time Latin-to-rune transliteration
- **3 themes:** Obsidian (dark), Parchment (warm), Nordic Dawn (cool)
- **Widgets:** Small/Medium/Large Home Screen + Circular/Inline Lock Screen
- **Collections:** All, Motivation, Stoic, Tolkien quote categories
- **Onboarding** flow with script preview and style selection
- **Accessibility:** VoiceOver, Dynamic Type, Reduce Motion support

## Documentation

- [XCODE_SETUP.md](XCODE_SETUP.md) -- Build setup and troubleshooting
- [WIDGET_SETUP.md](WIDGET_SETUP.md) -- Widget architecture and configuration
- [PERFORMANCE.md](PERFORMANCE.md) -- Performance targets and optimizations
