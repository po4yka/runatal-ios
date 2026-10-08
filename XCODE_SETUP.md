# Xcode Setup

## Current Toolchain

- Xcode 27.0 or newer
- Swift 6.4 (Swift 6 language mode)
- iOS deployment target: 26.0
- Recommended simulator for CLI validation: iPhone 17, iOS 27.0

The package requires Swift 6.4 tools, while `SWIFT_VERSION` uses the supported Swift 6 language mode (`6.0`). App and widget deployment targets remain iOS 26.0; builds use the iOS 27 SDK.

CI uses GitHub's [`xcode-27` Apple silicon image](https://github.com/actions/runner-images/blob/main/images/macos/xcode-27-arm64-Readme.md) with stable Xcode 27.0 selected explicitly. [The runner is currently in public preview](https://github.com/actions/runner-images/issues/14404).

## Required Tools

Install the local tooling once:

```bash
brew bundle
./scripts/ci/check-tool-versions.sh
```

- `xcodegen` Regenerates the `.xcodeproj` from `project.yml`.
- `needle` Regenerates the DI graph.
- `swiftlint` and `swiftformat` Match the repo’s validation commands.

## Quick Start

```bash
xcodegen generate
./scripts/generate-needle.sh
open RunicQuotes.xcodeproj
```

The checked-in `.xcodeproj` is derived from `project.yml`. Regenerate it after changing targets, resources, or large source moves, then commit both the project file and `project.yml` when needed.

## Recommended Validation Commands

```bash
swift build
swift test
swiftlint lint --strict
swiftformat --lint .
xcodebuild -scheme RunicQuotes \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0' \
  build
```

## What the Generators Handle

### `project.yml` / XcodeGen

- Target definitions for app, widget, and test bundles
- App Group and entitlements wiring
- Resource bundling for fonts, seed data, localization, and translation assets
- Shared source wiring for the widget target

### `scripts/generate-needle.sh`

- `RunicQuotes/DI/App/AppNeedleGenerated.swift`
- `RunicQuotesWidget/DI/WidgetNeedleGenerated.swift`

Run the Needle generator after changing any component or dependency declaration.

## Translation Asset Workflow

The bundled translation dataset is curated in `TranslationCuration/source/translation/`.

When those files change, refresh the runtime mirror:

```bash
./scripts/export-translation-assets.sh RunicQuotes/Resources/Translation
```

You can optionally pass a second destination for the Android mirror as documented in [TranslationCuration/README.md](TranslationCuration/README.md).

## Troubleshooting

### `needle` CLI not found

Install it with:

```bash
brew install needle
```

### Build input file cannot be found

This usually means the Xcode project is stale after a file move or deletion.

1. Run `xcodegen generate`.
2. If the file was intentionally removed, make sure the project definition and source tree agree.
3. Re-run the build.

### Translation assets fail to load

1. Verify `RunicQuotes/Resources/Translation/` contains the full mirrored JSON set.
2. Re-export from `TranslationCuration/source/translation/`.
3. Run `swift test --filter TranslationDatasetValidationTests`.

### Fonts render as boxes

1. Verify the `.ttf` files exist in `RunicQuotes/Resources/Fonts/`.
2. Regenerate the project if font resources changed.
3. Clean the build folder and rebuild.

### Widget target fails to read shared data

1. Check the App Group identifier in both entitlements files.
2. Confirm both the app and widget were regenerated from `project.yml`.
3. Reinstall the app if the simulator has stale shared-container data.
