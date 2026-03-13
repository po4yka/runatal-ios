# Translation Curation Package

`TranslationCuration` is the repo-level source-of-truth package for the offline historical translation dataset.

## Layout

- `source/translation/`
  Checked-in curated JSON with stable ids, source metadata, regression ids, and benchmark corpus files.

## Export workflow

Runtime clients do not edit generated copies directly.

Use:

```bash
./scripts/export-translation-assets.sh \
  /Users/po4yka/GitRep/runatal-ios/RunicQuotes/Resources/Translation \
  /Users/po4yka/GitRep/runatal-android/app/src/main/translationSeed/translation
```

The first path updates iOS runtime assets. The second path is optional and updates the Android mirror when that repo is available locally.

## Guarantees

- Stable ids are preserved across exports.
- `gold_corpus.json` travels with the runtime dataset for regression checks.
- Source metadata remains offline and bundled; the app never fetches translation data from the network.
