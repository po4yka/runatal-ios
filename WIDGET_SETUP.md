# Widget Setup

This document covers the `RunicQuotesWidget` extension and how it shares data with the main app.

## Scope

- WidgetKit extension configured with `AppIntentConfiguration`
- Home Screen and Lock Screen families
- Shared SwiftData container via App Groups
- Transliteration-first presentation

The widget target includes the shared translation models and storage schema for compatibility, but it does not currently expose the full historical translation UI or provenance surfaces that exist in the app.

## Widget Layout

```text
RunicQuotesWidget/
  DI/
    WidgetRootComponent.swift
    WidgetTimelineService.swift
    WidgetNeedleGenerated.swift
  Intents/
    WidgetConfigurationIntent.swift
  Models/
    DeepLink.swift
    RunicQuoteEntry.swift
  Provider/
    QuoteTimelineProvider.swift
  Views/
    WidgetViews.swift
  RunicQuoteWidget.swift
```

## Shared Code

Per `project.yml`, the widget target compiles shared code from:

- `RunicQuotes/Models`
- `RunicQuotes/Data`
- `RunicQuotes/Utilities`
- `RunicQuotes/DI/Shared`

This gives the widget access to:

- quote and preference models
- transliteration logic
- shared SwiftData helpers
- translation cache models needed for shared schema compatibility
- theme and font utilities

## Data Sharing

App and widget share data through the App Group `group.com.po4yka.runicquotes`.

Shared state includes:

- SwiftData quote store
- user preferences such as script, font, and theme
- widget mode and style preferences

`QuoteTimelineProvider` builds its entries from `WidgetTimelineService`, which loads preferences from the shared container and chooses either a quote of the day or a random quote.

## Configuration Surface

The widget uses `RunicQuoteConfigurationIntent` for per-widget settings:

- script
- widget mode
- widget style
- whether decorative rune text is shown

Theme and font still come from the shared app preferences.

## Supported Families

### Home Screen

- `systemSmall`
- `systemMedium`
- `systemLarge`

### Lock Screen / accessory

- `accessoryCircular`
- `accessoryRectangular`
- `accessoryInline`

## Update Policy

- `Daily`
  Uses deterministic quote-of-the-day selection and refreshes at midnight.
- `Random`
  Refreshes hourly with a new quote.

The timeline provider emits a current entry plus the next scheduled update entry.

## Deep Linking

Widgets open the app through the `runicquotes://` URL scheme.

Current deep-link behavior can carry quote-tab context such as the selected script so the main app lands in the expected viewing state.

## Troubleshooting

### Widget shows placeholder content

1. Confirm the app has seeded quotes in the shared container.
2. Check that the widget and app use the same App Group entitlements.
3. Reinstall the app if the simulator has stale shared-container data.

### Fonts do not render correctly

1. Verify the runic `.ttf` files are bundled in both targets through `project.yml`.
2. Regenerate the project after changing resource declarations.
3. Clean the build folder and rebuild.

### Widget target fails after shared model changes

1. Run `xcodegen generate`.
2. Run `./scripts/generate-needle.sh`.
3. Make sure shared app files referenced by the widget still exist and still compile for extension-safe contexts.
