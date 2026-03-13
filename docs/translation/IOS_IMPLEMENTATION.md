# iOS Translation Implementation

This document describes the iOS translation feature added in March 2026.

## Scope

- `Transliterate` remains the default presentation mode.
- `Translate` is fully user-facing on iOS and available from:
  - Settings -> Translation
  - Home toolbar -> Create menu -> Translate

## Bundled assets

- Curated JSON is maintained in `TranslationCuration/source/translation/`.
- Runtime mirrors are exported into `RunicQuotes/Resources/Translation/`.
- The iOS runtime loads the same manifest, lexicon, phrase-template, corpus-reference, gold-corpus, and Erebor-table files as Android when the mirrored dataset is exported there.
- SwiftPM also processes the translation resource directory so `swift build` and `swift test` exercise the same offline dataset.

## Runtime architecture

- `HistoricalTranslationService` ports the Android precedence rules for:
  - Younger Futhark historical translation
  - Elder Futhark constrained reconstruction
  - Erebor/Cirth transcription
- The service now performs an explicit English-input analysis stage before token resolution.
- Unsupported non-English input is rejected with guidance instead of silently fabricating approximate output.
- `AssetTranslationDatasetProvider` backs the service with bundled JSON and caches decoded payloads in memory.
- `SwiftDataTranslationRepository` stores structured results in:
  - `TranslationRecord`
  - `TranslationBackfillState`
- `TranslationProvider` mirrors the existing quote actor pattern for serialized cache access.

## Persistence behavior

- Quote creation and editing now accept an optional `RunicTextBundle` override.
- Standard quote flows still persist transliterations.
- Translation-screen saves persist the generated runic outputs exactly.
- When a quote’s Latin text changes, cached structured translations for that quote are deleted.

## Home and share behavior

- Home prefers the latest cached structured translation for the selected script.
- If no structured translation exists, Home falls back to the stored quote field.
- If the stored quote field is empty, Home falls back to on-demand transliteration.
- Share inherits this automatically because it uses the current Home presentation state.
- Both Home and Share now disclose whether the runic text is a structured historical translation or a transliteration fallback.

## Quality and support surfaces

- Translation now displays:
  - English-only source-language disclosure
  - support and evidence badges
  - primary source summary
  - provenance detail sheet
  - user-facing warnings for unsupported constructions
- The accuracy screen now explains evidence badges and English-only support.

## Release gating

- `gold_corpus.json` stores stable benchmark cases for exact-match regression checks.
- `TranslationDatasetValidationTests` validates source metadata, stable ids, inventories, and attestation refs.
- `TranslationQualityRegressionTests` compares normalized, diplomatic, glyph, support, and evidence output against the benchmark corpus.

## Startup backfill

- After seed and purge work completes, the app runs a utility-priority translation backfill.
- Backfill warms the dataset provider, scans all non-deleted quotes, and caches strict Elder and Younger results when available.
- Cirth is intentionally skipped during startup backfill to match the rollout plan.

## Cirth rendering adaptation

- Android stores Erebor glyph strings with a different glyph mapping strategy.
- iOS does not reuse those raw glyph strings directly.
- Instead, iOS rerenders Cirth output from the diplomatic layer using the existing `CirthAngerthas.ttf` Latin-substitution font mapping.
- This preserves logical parity with Android while staying compatible with the current Angerthas font bundled in the iOS app.
