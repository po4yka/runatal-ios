# Performance

Performance goals and implementation notes for RunicQuotes.

## Engineering Goals

These are maintenance targets, not hard product guarantees:

| Area | Goal |
| --- | --- |
| Cold app launch | Keep startup work off the main thread |
| Quote rendering | Maintain smooth 60 FPS interaction on supported devices |
| Widget timeline generation | Stay on a fast local-data path with no network dependency |
| Translation generation | Asset-backed, deterministic, and fully offline |
| Store access | Keep quote and cache fetches local and narrowly scoped |

## Startup Strategy

- `ModelContainer` is created once during app startup and shared through dependency injection.
- Seed and purge work run asynchronously instead of blocking the initial view tree.
- Translation backfill runs at utility priority after startup work completes.
- The historical translation dataset is warmed once and then cached in memory by `AssetTranslationDatasetProvider`.

## Translation Runtime

- Translation is fully offline and bundled with the app.
- Decoded dataset payloads are cached in memory to avoid repeated JSON parsing.
- Strict-mode generation refuses unsupported output rather than spending work on speculative fallbacks.
- Gold-corpus regression tests keep performance work from weakening output quality guarantees.

## UI Rendering

- ViewModels publish only screen state that affects visible UI.
- Quote and translation surfaces derive presentation from lightweight state structs.
- Runic output uses bundled fonts with script-aware rendering paths.
- The app relies on native SwiftUI materials, gradients, and transitions rather than custom rendering pipelines.

## Data Access

- `QuoteProvider` and `TranslationProvider` serialize access through actors instead of manual locking.
- `QuoteRepository` and `TranslationRepository` keep fetches scoped to the current quote, script, or cache key.
- Translation cache entries are keyed by quote, script, fidelity, variant, engine version, and dataset version to avoid expensive ambiguity at read time.

## Widgets

- The widget timeline provider uses the shared local container only.
- `Daily` mode computes the next refresh at midnight.
- `Random` mode refreshes hourly.
- Timeline entries are lightweight and derived from already-local quote data.

## What to Measure

When performance changes matter, check:

- app cold launch after a clean install
- first translation request after launch
- repeated translation requests with a warm dataset cache
- quote switching and script switching on the home screen
- widget timeline generation and refresh behavior

## Practical Validation

Use the normal repo checks first:

```bash
swift test
swiftlint lint --strict
swiftformat --lint .
xcodebuild -scheme RunicQuotes \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' \
  build
```

For targeted translation work, also run:

```bash
swift test --filter TranslationDatasetValidationTests
swift test --filter TranslationQualityRegressionTests
swift test --filter HistoricalTranslationServiceTests
```
