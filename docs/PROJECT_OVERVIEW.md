# Project Overview

RunicQuotes is a SwiftUI iOS application with a WidgetKit extension and an offline historical translation subsystem. This document is the project-level entry point for developers working on the app.

## Targets

- `RunicQuotes`
  Main iOS application target.
- `RunicQuotesWidget`
  WidgetKit extension with App Intent configuration.
- `RunicQuotesTests`
  Unit and package-level tests.
- `RunicQuotesUITests`
  End-to-end UI validation.
- `RunicQuotesWidgetTests`
  Widget-specific tests.
- `TranslationCuration`
  Repo-level source-of-truth package for the bundled translation dataset.

## Architecture

The app uses a pragmatic layered structure:

- MVVM for screen orchestration
- Repository protocols backed by SwiftData implementations
- Actors for serialized data access and background work
- Needle for dependency injection
- XcodeGen for project generation

Important runtime boundaries:

- `RunicTransliterator`
  Direct Latin-to-rune transliteration.
- `HistoricalTranslationService`
  Offline structured translation and Cirth transcription.
- `QuoteRepository` / `TranslationRepository`
  Persistence and cache orchestration.
- `QuoteProvider` / `TranslationProvider`
  Actor-backed serialized access.

## Main Runtime Flows

### Quotes and transliteration

- Seed quotes are bundled locally in `RunicQuotes/Resources/SeedData/`.
- The home quote flow reads from SwiftData and renders transliterated or structured runic output depending on availability.
- Editing a quote can invalidate cached structured translations when the Latin source changes.

### Historical translation

- Curated JSON lives in `TranslationCuration/source/translation/`.
- Runtime mirrors are bundled in `RunicQuotes/Resources/Translation/`.
- Translation is strictly offline and currently supports English input only.
- Results carry provenance, support/evidence state, normalized/diplomatic layers, and unresolved-token diagnostics.

### Widgets

- Widgets read from the shared App Group SwiftData container.
- Widget configuration is handled by `RunicQuoteConfigurationIntent`.
- Widget presentation remains transliteration-first even though the shared schema includes translation cache models.

## Repository Map

```text
RunicQuotes/
  App/                app lifecycle and root composition
  Data/
    Actors/           actor-backed providers
    Repositories/     persistence and cache implementations
    Translation/      dataset provider and historical translation engine
    Transliteration/  direct script mapping
  DI/                 Needle components and generated files
  Environment/        environment wiring for shared services
  Models/
    Enums/            scripts, themes, widget modes, collections
    Translation/      translation request/result model layer
  Resources/
    Fonts/
    Localizations/
    SeedData/
    Translation/
  Utilities/          logging, themes, helpers
  ViewModels/         screen state
  Views/
    Components/
    Quote/
    Settings/
    Translation/
```

## Development Workflow

1. Regenerate the Xcode project after structural `project.yml` changes.
2. Regenerate Needle output after DI graph changes.
3. Export translation mirrors after editing `TranslationCuration`.
4. Run unit tests, lint, and formatting checks before submitting.

Typical commands:

```bash
xcodegen generate
./scripts/generate-needle.sh
./scripts/export-translation-assets.sh RunicQuotes/Resources/Translation
swift build
swift test
swiftlint lint --strict
swiftformat --lint .
```

## Documentation Map

- [../XCODE_SETUP.md](../XCODE_SETUP.md)
- [../WIDGET_SETUP.md](../WIDGET_SETUP.md)
- [../PERFORMANCE.md](../PERFORMANCE.md)
- [translation/IOS_IMPLEMENTATION.md](translation/IOS_IMPLEMENTATION.md)
- [translation/IMPLEMENTED_ARCHITECTURE.md](translation/IMPLEMENTED_ARCHITECTURE.md)
- [translation/CURATION_POLICY.md](translation/CURATION_POLICY.md)
- [translation/FUTURE_RESEARCH.md](translation/FUTURE_RESEARCH.md)
- [../TranslationCuration/README.md](../TranslationCuration/README.md)
