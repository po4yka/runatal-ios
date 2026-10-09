# Translation System Architecture

This directory documents the translation system that is implemented in the app today.

## Runtime scope

The app ships two separate stacks:

- `RunicTransliterator` for modern spelling transcription with visible unsupported characters
- `HistoricalTranslationService` for structured historical translation and Erebor transcription

`Transliterate` remains the default user-facing mode. `Translate` is fully user-facing on iOS with structured output layers, evidence badges, and provenance.

## Direct transcription contract

`RunicTransliterator.transliterate(_:to:)` returns `RunicTransliterationResult`, containing `glyphOutput`, `unresolvedCharacters`, and user-facing `warnings`. Callers explicitly select `glyphOutput` when storing a string. Latin diacritics and supported spelling forms are normalized; unknown letters and symbols remain visible rather than being discarded. Numbers and punctuation are retained literally.

Elder output uses the canonical 24-graph inventory. Younger output uses the 16 long-branch graphs; historical output can instead select the short-twig variant. These modern spelling mappings are approximations, not a claim that an English sentence is Old Norse or Proto-Norse.

Cirth uses the proposed CSUR private-use graph encoding and the renamed OFL-licensed `RunatalCirth-Regular.ttf` subset. `CirthGraph` shares Appendix E graph identities and Angerthas Erebor sound assignments with the reference catalog. Graph shapes and certh numbers differ from scalar ordinals where the source has variants. CSUR is not a standardized Unicode script, and copied glyph strings require a compatible font. Modern Cirth is spelling transcription, not automatic English phoneme analysis.

## Translation engines

The translation stack is offline and asset-backed. It currently exposes three engines:

- `YoungerFutharkTranslationEngine` English -> normalized Old Norse -> diplomatic Latin rune spelling -> Younger Futhark glyphs
- `ElderFutharkTranslationEngine` English -> constrained Proto-Norse reconstruction -> Elder Futhark glyphs
- `EreborCirthTranslationEngine` English transcription -> Erebor diplomatic sequence layer -> Cirth glyphs

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

- `HistoricalLexiconStore` Old Norse and Proto-Norse lexicon entries, paradigm tables, grammar rules, name adaptations, and fallback templates
- `RunicCorpusStore` gold examples, Younger phrase templates, Elder attested forms, and runic corpus references
- `EreborOrthographyStore` Erebor sequence tables, phrase mappings, long-vowel and long-consonant tables

The repo-level source of truth lives in:

- `TranslationCuration/source/translation/`

The shipped `AssetTranslationDatasetProvider` eagerly loads an immutable, checked `Sendable` snapshot of all 14 assets. Its initializer throws on missing resources, malformed required metadata, unknown enums, out-of-range confidence, duplicate IDs, dangling references, or invalid inflection keys. It reads mirrored runtime JSON from:

- `RunicQuotes/Resources/Translation/`

The resource schema requires explicit evidence status and inventory eligibility; absence never means attested or approved. Rule inventories include source scope. Dictionary headwords support lexical forms, not entire app-authored sentences. Synthetic examples are credited to Runatal; institutional sources are cited only for the facts they support. A dataset load failure produces a typed unavailable historical result with a visible explanation while direct transcription remains usable.

The current JSON contract includes mandatory metadata and `paraphrasesByStage`; consumers of earlier exports must update their decoders. There is no parallel legacy runtime schema. Export all 14 source assets together with `scripts/export-translation-assets.sh`.

## Bounded Old Norse grammar

`OldNorseSentenceGrammar` composes a single subject–verb clause and supported noun phrases using explicit cited forms. The initial corpus covers the finite indicative forms of `vera`, `hafa`, and `veiða`, subject person/number/tense, nominative and accusative noun phrases, strong adjective case/gender/number agreement, location `í` with dative, direction `í` with accusative, and associative `með` with dative. Definite noun forms and irregular plurals such as `fjǫll` are stored explicitly. English suffix guesses do not manufacture inflections.

Examples include `I am` → `ek em`, `He has a wolf` → `hann hefir úlf`, `I hunt a great wolf` → `ek veiði mikinn úlf`, and `He is in a great mountain` → `hann er í miklu fjalli`. Unsupported agreement, unknown subject gender for an adjective, multiple clauses, and nested prepositions receive partial/approximate output and explicit warnings. A clear initial finite agreement can survive an unsupported later clause without assigning object case across its boundary. See [Barnes, NION I](https://vsnr.org/wp-content/uploads/2021/11/NION-1.pdf), especially §§3.1, 3.3, 3.6, 3.7 and 3.9.7.1.

## Selection precedence

The engines do not use one generic fallback path. They use precedence rules:

- Younger Futhark gold example -> curated phrase template -> token composition -> readable/decorative fallback -> strict unavailable
- Elder Futhark gold example -> curated attested short form/template -> readable/decorative token composition -> strict unavailable
- Erebor gold example -> curated phrase mapping -> sequence-table transcription -> readable character fallback -> strict unavailable

The historical semantic track supports declared English input and rejects detected unsupported scripts. Detection is conservative rather than general natural-language identification. The complete grapheme tokenizer preserves negation, smart-apostrophe contractions, numbers, and symbols. Unknown modern spelling is labeled `MODERN_ENGLISH` or `MIXED_HISTORICAL_AND_MODERN`, rather than being presented as an ancient language. Old Norse paraphrases cannot enter the Proto-Norse inventory.

## Persistence

Structured translation output is stored in SwiftData:

- `translation_records` cached translation results keyed by quote, script, fidelity, variant, engine version, and dataset version
- `translation_backfill_state` resumable one-time backfill progress

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

`STRICT` uses explicitly eligible inventories and cited lexical forms. Missing lexical support or an ineligible unverified formula returns `UNAVAILABLE`. A lexical gloss for unsupported sentence grammar may remain visible, but it is labeled partial/approximate with warnings and does not claim supported complete translation.

Strict generated glyph output and every glyph trace also pass a service-boundary inventory check: Elder 24 graphs, the selected Younger 16-graph variant, or the licensed Cirth CSUR core. Only declared literal source numbers/symbols can accompany these graphs. A valid JSON record with a bad lemma or Latin gold glyph yields a typed unavailable result, never visible strict output.

Strict results require provenance. `attestedOnly` additionally requires a complete attested phrase at the final service boundary; capitalized names, lexical composition, and readable fallbacks cannot bypass this cap. Confidence is a deterministic support heuristic, not a calibrated scholarly probability.

`READABLE` and `DECORATIVE` may use curated paraphrase or phonological-preservation fallbacks, but those results must be marked as approximations.

The app also ships `gold_corpus.json` and regression tests so normalized, diplomatic, and glyph output can be checked release-to-release.

## Historical corpus and reference scope

The catalog includes four source-backed inscription entries: Gallehus DR 12, Vimose DR 207, and the first memorial clauses of Jelling DR 41 and DR 42. DR 41 explicitly carries reconstructed/restored reading status; the other selected sequences carry attested status. Their English literals and segmented readings cite the named [RuneS entries](https://www.runesdb.de/), with license/origin notices retained. Standard display glyphs are not facsimiles. Proposed `wulfaz` and `kuningaz` lexical spellings remain reconstructions, not verified inscription attestations. The modern aphorism and public-domain pack catalog is not a promise of strict historical translation for every row.

Rune reference separates comparative Elder-name reconstructions, medieval Younger rune-poem traditions, and Tolkien's fictional numbered graphs from project-authored modern reflection prompts. Source links identify whether they support glyph identity, later comparative names, or the fictional mode table; modern esoteric interpretations are not presented as ancient evidence.

## Versioned glyph migration

Only exact frozen automatically generated Elder/Younger outputs are refreshed; custom fields and permanent saved historical artifacts are preserved. Cirth's retired Latin-font slots migrate by graph identity, including the old `x` outline as `k+s`. Exact generated legacy output may be refreshed to canonical spelling; arbitrary saved/custom graph strings are never retranslated from their Latin source. The original placeholder codec is recognized by complete frozen output equality, not merely a PUA character. Unknown PUA retains its bytes and an explicit unknown-encoding marker. Valid permanent Cirth traces migrate graph strings while retaining the original engine receipt, layers, dates, and provenance; unreadable metadata bytes are retained with a diagnostic. These codecs exist only as versioned data migrations, not live alternative render paths.
