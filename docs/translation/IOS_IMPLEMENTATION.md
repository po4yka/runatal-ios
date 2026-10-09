# iOS Translation Implementation

This document describes the current iOS translation contracts, including the source and rune corrections introduced in October 2026.

## Scope

- `Transliterate` remains the default presentation mode.
- `Translate` is fully user-facing on iOS and available from: - Settings -> Translation - Home toolbar -> Create menu -> Translate

## Bundled assets

- Curated JSON is maintained in `TranslationCuration/source/translation/`.
- Runtime mirrors are exported into `RunicQuotes/Resources/Translation/`.
- The 14-file schema has mandatory evidence metadata, explicit gold inventory eligibility, and stage-separated paraphrases. External consumers of older exports must update their decoders; glyph mapping and resource parity cannot be assumed from copying JSON alone.
- SwiftPM also processes the translation resource directory so `swift build` and `swift test` exercise the same offline dataset.

## Runtime architecture

- `HistoricalTranslationService` ports the Android precedence rules for: - Younger Futhark historical translation - Elder Futhark constrained reconstruction - Erebor/Cirth transcription
- English analysis feeds cited finite verb and case/agreement rules in `OldNorseSentenceGrammar`. Supported positive forms include `ek em`, `hann hefir úlf`, `ek veiði mikinn úlf`, and `hann er í miklu fjalli`; unsupported grammar remains an explicitly marked partial approximation.
- Declared English is the supported semantic input. Unsupported scripts are rejected; the detector is not general natural-language identification. Complete grapheme tokenization retains smart contractions, negation, digits, and literal symbols.
- `AssetTranslationDatasetProvider` is an eager immutable `Sendable` snapshot. Construction throws before a partial store escapes; strict field decoding and cross-reference validation reject malformed metadata. The service exposes a typed unavailable historical result on load failure while modern transcription remains available.
- `SwiftDataTranslationRepository` stores structured results in: - `TranslationRecord` - `TranslationBackfillState`
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

- Translation now displays: - English-only source-language disclosure - support and evidence badges - primary source summary - provenance detail sheet - user-facing warnings for unsupported constructions
- The accuracy screen now explains evidence badges and English-only support.

## Release gating

- `gold_corpus.json` stores stable benchmark cases for exact-match regression checks.
- `TranslationDatasetValidationTests` validates source metadata, stable ids, inventories, and attestation refs.
- `TranslationQualityRegressionTests` compares normalized, diplomatic, glyph, support, and evidence output against the benchmark corpus.

## Startup backfill

- After seed and purge work completes, the app runs a utility-priority translation backfill.
- Backfill uses the already-loaded immutable dataset snapshot; selection and versioned progress are managed by `TranslationBackfillWorker`.
- Cirth is intentionally skipped during startup backfill to match the rollout plan.

## Direct and Cirth rendering contracts

- Direct transcription returns `RunicTransliterationResult`; callers store `.glyphOutput` and expose unresolved-character warnings.
- Canonical Elder and Younger glyph inventories replace mixed historical glyph variants in direct output.
- Cirth glyph strings use the proposed CSUR private-use encoding, rendered with `RunatalCirth-Regular.ttf`. The derived subset retains the original Kurinto copyright/OFL and uses a new font name to respect the reserved name. Both app and widget bundle/register the font and retain its license; hidden resource placeholders are excluded from copy phases.
- The historical Cirth renderer maps complete diplomatic segments to actual Erebor graph identities, preserving segment boundaries. It does not strip separators and accidentally reinterpret adjacent letters as a digraph.
- `CirthGraph` supplies shared verified certh numbers, graph shapes, and mode notes for live modern transcription and the reference catalog. Source [Appendix E table](https://mirrors.mit.edu/CTAN/fonts/cirth/cirth.pdf) and [CSUR registry](https://www.evertype.com/standards/csur/cirth.html) support those assignments, not project-authored example sentences.
- Old saved/custom Latin-slot Cirth migrates shape by shape; the old `x` is two graphs `k+s`. Permanent historical layers and old engine receipts survive. Exact generated outputs can be refreshed after a frozen old-engine match. Unknown custom PUA and corrupt permanent metadata are preserved.

## Evidence and source boundaries

- `attestedOnly` is checked against the final complete phrase; fallback and lexical paths cannot pass with unverified attestation labels.
- The four genuine inscription catalog rows provide positive named historical coverage. DR 41 is an explicit restored reconstruction, not an intact attested sequence.
- Old Norse paraphrases are stage-scoped. Modern English preservation and mixed output disclose that meaning has not been historically translated.
- Reference cards classify reconstructed names, medieval poem traditions, and fictional Cirth separately. Modern reflection prompts are clearly project-authored; each glyph has source links with scope.
- `StrictTranslationDatasetTests` exercises missing required metadata in all 14 resource families, invalid statuses/confidence, dangling provenance, graceful corrupt-dataset behavior, and retained positive inscription coverage. Grammar and Cirth contract tests assert independent source-derived positive outputs; synthetic educational examples do not borrow institutional quotation authority.
