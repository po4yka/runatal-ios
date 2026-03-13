# Translation System Architecture

This directory documents the translation system that is implemented in the app today.

## Runtime scope

The app ships two separate stacks:

- `RunicTransliterator` for legacy direct letter-to-rune transliteration
- `HistoricalTranslationService` for structured historical translation and Erebor transcription

`Transliterate` remains the default user-facing mode. `Translate` is fully user-facing on iOS with structured output layers, evidence badges, and provenance.

## Translation engines

The translation stack is offline and asset-backed. It currently exposes three engines:

- `YoungerFutharkTranslationEngine`
  English -> normalized Old Norse -> diplomatic Latin rune spelling -> Younger Futhark glyphs
- `ElderFutharkTranslationEngine`
  English -> constrained Proto-Norse reconstruction -> Elder Futhark glyphs
- `EreborCirthTranslationEngine`
  English transcription -> Erebor diplomatic sequence layer -> Cirth glyphs

Each engine returns `TranslationResult` with:

- source text
- target script
- fidelity
- derivation kind
- historical stage
- normalized form
- diplomatic form
- glyph output
- support level
- evidence tier
- resolution status
- confidence
- notes
- unresolved tokens
- provenance
- token breakdown
- attestation refs
- input language
- user-facing warnings
- engine version
- dataset version

## Data sources and stores

The runtime dataset is split into three internal stores:

- `HistoricalLexiconStore`
  Old Norse and Proto-Norse lexicon entries, paradigm tables, grammar rules, name adaptations, and fallback templates
- `RunicCorpusStore`
  gold examples, Younger phrase templates, Elder attested forms, and runic corpus references
- `EreborOrthographyStore`
  Erebor sequence tables, phrase mappings, long-vowel and long-consonant tables

The repo-level source of truth lives in:

- `TranslationCuration/source/translation/`

The shipped provider is `AssetTranslationDatasetProvider`, which reads mirrored runtime JSON assets from:

- `RunicQuotes/Resources/Translation/`

## Selection precedence

The engines do not use one generic fallback path. They use precedence rules:

- Younger Futhark
  gold example -> curated phrase template -> token composition -> readable/decorative fallback -> strict unavailable
- Elder Futhark
  gold example -> curated attested short form/template -> readable/decorative token composition -> strict unavailable
- Erebor
  gold example -> curated phrase mapping -> sequence-table transcription -> readable character fallback -> strict unavailable

All three engines now run an explicit English-input analysis stage before token resolution. Unsupported source language is rejected early with guidance instead of silently fabricating output.

## Persistence

Structured translation output is stored in SwiftData:

- `translation_records`
  cached translation results keyed by quote, script, fidelity, variant, engine version, and dataset version
- `translation_backfill_state`
  resumable one-time backfill progress

`TranslationRepository` owns cache lookup, persistence, lazy generation, and backfill behavior.

## UI surfaces

The translation screen can display:

- mode toggle
- script selector
- fidelity selector
- Younger variant selector
- English-only source-language disclosure
- support and evidence badges
- normalized and diplomatic layers
- resolution badge
- derivation label
- provenance
- primary source summary
- token breakdown
- unavailable explanation

Home and Share also disclose whether the currently visible runic text is:

- a structured historical translation
- a stored transliteration fallback
- a live transliteration generated on demand

Quote and share surfaces can prefer cached structured translations when available and otherwise fall back to stored transliteration output.

## Accuracy policy

`STRICT` is conservative. If the engine cannot produce a defensible result, it returns `UNAVAILABLE` with notes and unresolved tokens instead of fabricating output.

Strict results must also carry provenance. If the engine cannot resolve a defensible source-backed path, it does not emit a visible strict result.

`READABLE` and `DECORATIVE` may use curated paraphrase or phonological-preservation fallbacks, but those results must be marked as approximations.

The app also ships `gold_corpus.json` and regression tests so normalized, diplomatic, and glyph output can be checked release-to-release.
