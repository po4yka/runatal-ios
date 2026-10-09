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

## Persistence and input behavior

- Quote creation commits the quote, exact stored output and structured result records in one dedicated mutation context.
- Metadata-only edits retain exact glyphs and permanent assessment metadata. Changing the Latin source clears derived caches and replaces generated fields.
- Cache approval requires the actual quote source and current engine/dataset versions; batched lookups share that policy.
- Public repository/editor input is limited to 10,000 characters with nonblank text/author and an assignable collection. Studio keeps its 280-character limit. Oversized paste remains intact with a visible error and cannot be saved as a truncated prefix.
- Curated templates, gold examples and Cirth phrases permit only modern terminal `.`, `!` and `?` to vary in phrase matching. Source text and symbols are retained; punctuation has no borrowed inscription provenance and receives an explicit warning.

## Library and share presentation

- The shared resolver prefers valid permanent saved assessments, then exact custom or opaque saved glyphs, then current approved cache, then stored/generated modern transcription.
- Recorded saved evidence remains inspectable with its original versions and sources; it is not represented as a fresh assessment.
- Historical, modern English spelling and mixed result stages have distinct disclosure. Unsupported-character warnings accompany the actual displayed output.
- Saved/Search/Archive use the current selected script and compatible font, with one batched cache lookup over a coherent visible/archived library snapshot. Saved/Search open the actual quote UUID.
- Home commits each complete presentation atomically and discards cancelled or superseded actor responses.
- The original passage source is exposed separately from translation provenance. Explicit HTTP(S) links require a user tap.
- Share uses the same resolved output, wraps full rune text and source disclosures, and includes all output in the text fallback. Rune and source text use readable contrast; system serif body and rune fonts respect Dynamic Type without double scaling. Cirth copying discloses its private-use compatible-font requirement.

## Widget and reminder behavior

- Widget intent defaults follow app preferences; explicit per-widget overrides include collection/script/mode/style/decorations. Effective fonts match the script.
- Live widget content follows the shared presentation resolver. Empty and unavailable libraries produce explicit status entries; samples appear only in preview/placeholder paths.
- Daily refresh uses the next local calendar midnight. Successful preference/library writes request widget reloads with bounded coalescing.
- Widget taps route to the displayed quote UUID in temporary context; they do not persist widget overrides into app preferences.
- A persistent daily reading reminder schedules an actual owned repeating `UNCalendarNotificationTrigger`. Enabled state follows successful authorization, scheduling and preference persistence; errors and recovery are visible. Off removes only the owned request. Reminder taps open the current daily quote using current preferences after bootstrap.

## Quality and support surfaces

- Translation now displays: - English-only source-language disclosure - support and evidence badges - primary source summary - provenance detail sheet - user-facing warnings for unsupported constructions
- The accuracy screen now explains evidence badges and English-only support.

## Release gating

- `gold_corpus.json` stores stable benchmark cases for exact-match regression checks.
- `TranslationDatasetValidationTests` validates source metadata, stable ids, inventories, and attestation refs.
- `TranslationQualityRegressionTests` compares normalized, diplomatic, glyph, support, and evidence output against the benchmark corpus.
- Native UIKit/CoreText tests require registered fonts and complete Elder, both Younger variants and Cirth glyph coverage. Native share tests attach six genuine 320-point exports. `RunicQuotesUICI` executes the complete UI target, including positive provenance, migration identity, bookmark events, real pack installation and reminder interactions; it has no skipped/focused cases.

## Startup backfill

- A startup barrier awaits seed/import migration and throwing expiry purge before Home becomes available. Failure presents retry; incoming routes are retained until the consumer is ready.
- After that barrier, the app runs a utility-priority translation backfill and refreshes the visible quote on successful cache events.
- Backfill uses the already-loaded immutable dataset snapshot; `TranslationBackfillWorker` commits bounded 32-row batches with per-quote source/version signatures, cancellation and resumable progress.
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
