# Widget Setup

Architecture and configuration for the RunicQuotesWidget extension.

## Architecture

```
RunicQuotesWidget/
  RunicQuoteWidget.swift       Widget entry point, supported families
  Provider/
    QuoteTimelineProvider.swift Timeline generation (daily/hourly)
  Models/
    RunicQuoteEntry.swift       TimelineEntry with quote data
  Views/
    *.swift                     Widget views per family size
```

The widget shares code from the main app via `project.yml` source includes:
- `RunicQuotes/Models/` -- data models and enums
- `RunicQuotes/Data/` -- repositories and transliteration
- `RunicQuotes/Utilities/` -- font config, theme palette, extensions

## Data Sharing

App and widget share data via **App Groups** (`group.com.po4yka.runicquotes`):
- Shared `ModelContainer` for SwiftData access
- User preferences (script, font, theme, widget mode)

## Supported Widget Families

### Home Screen
- **Small:** Runic text with script name
- **Medium:** Runic text + Latin translation + author
- **Large:** Full quote with header and dividers

### Lock Screen
- **Circular:** Single runic character
- **Rectangular:** Runic text + author
- **Inline:** Runic text only

## Widget Modes

- **Daily:** Updates at midnight, deterministic quote-of-the-day
- **Random:** Updates every hour with a random quote

## Deep Linking

Tapping a widget opens the app via `runicquotes://` URL scheme:
- `runicquotes://quote?script=elder` -- opens Quote tab with specified script
- Handled in `RunicQuotesApp.swift` via `onOpenURL`

## Troubleshooting

### Fonts not rendering in widget
- Verify `UIAppFonts` is set in `RunicQuotesWidget/Info.plist` (handled by `project.yml`)
- Clean build: Cmd+Shift+K

### Widget shows "Unable to Load"
- Both targets must use the same App Group identifier
- Shared source files must compile for the widget target

### Widget not updating
- Remove and re-add the widget on the Home Screen
- Force-quit the app to reset the widget process
