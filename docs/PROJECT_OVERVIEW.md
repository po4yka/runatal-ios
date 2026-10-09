# Project Overview

RunicQuotes is a SwiftUI iOS application with a WidgetKit extension and an offline historical translation subsystem. This document is the project-level entry point for developers working on the app.

## Targets

- `RunicQuotes` Main iOS application target.
- `RunicQuotesWidget` WidgetKit extension with App Intent configuration.
- `RunicQuotesTests` Unit and package-level tests.
- `RunicQuotesUITests` End-to-end UI validation.
- `RunicQuotesWidgetTests` Widget-specific tests.
- `TranslationCuration` Repo-level source-of-truth package for the bundled translation dataset.

## Architecture

The app uses a pragmatic layered structure:

- MVVM for screen orchestration
- Repository protocols backed by SwiftData implementations
- ModelActor-owned executors for serialized access; repositories use dedicated mutation contexts so rollback never discards unrelated UI work
- Needle for dependency injection
- XcodeGen for project generation

Important runtime boundaries:

- `RunicTransliterator` Modern spelling transcription returning glyphs plus unresolved-character warnings.
- `HistoricalTranslationService` Offline structured translation with cited bounded grammar, whole-phrase evidence caps, and Erebor transcription.
- `QuoteRepository` / `TranslationRepository` Persistence and cache orchestration.
- `QuoteProvider` / `TranslationProvider` Actor-backed serialized access.

## Main Runtime Flows

### Quotes and transliteration

- Seed quotes are bundled locally in `RunicQuotes/Resources/SeedData/`.
- The home quote flow reads from SwiftData and renders transliterated or structured runic output depending on availability.
- Metadata-only edits preserve exact saved output and its assessment. Changed Latin sources invalidate derived cache.
- Seed/import migration and expiry purge finish before Home mounts; launch routes wait for that barrier. Versioned backfill then runs in bounded batches.
- Home publishes complete generation-checked state; Saved/Search refresh after real writes and open exact quote IDs.
- Shared rune presentation preserves permanent/custom artifacts before current approved cache, with explicit recorded-evidence, stage, unsupported-character and encoding disclosures. Original passage source and translation provenance have separate sheets.

### Historical translation

- Curated JSON lives in `TranslationCuration/source/translation/`.
- Runtime mirrors are bundled in `RunicQuotes/Resources/Translation/`.
- Translation is strictly offline and currently supports English input only.
- Results carry provenance, support/evidence state, normalized/diplomatic layers, and unresolved-token diagnostics.

The provider strictly loads all 14 assets into an immutable snapshot; a malformed dataset yields an explicit unavailable historical result while direct transcription still works. Genuine RuneS inscription rows provide positive historical coverage; ordinary modern quotes and installed packs do not imply strict ancient-language support. Cirth uses a licensed renamed CSUR font subset, and reference content separates historical reconstruction, medieval poem traditions, fictional mode facts, and modern interpretation. See `docs/translation/IMPLEMENTED_ARCHITECTURE.md` for grammar, encoding, source scope, and versioned migration contracts.

### Widgets

- Widgets read from the shared App Group SwiftData container.
- Widget configuration is handled by `RunicQuoteConfigurationIntent`.
- App defaults and independent widget overrides cover collection, script, mode, style and decorations; effective fonts are compatible.
- Widgets use the shared rune presentation policy, explicit live empty/error entries and preview-only samples. Daily refresh follows local calendar midnight, and successful writes request reloads.
- Widget links open the displayed UUID with temporary context, preserving app preferences.

### Daily reading reminder

- Settings and onboarding control an actual repeating local calendar notification with persisted time and on/off state.
- Authorization, scheduling and persistence failures are visible; disabling cancels only the owned request.
- Reminder taps wait for bootstrap and open the current daily quote with current reading preferences.

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
