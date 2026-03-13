# RunicQuotes

RunicQuotes is an iOS app for reading and saving quotes in Elder Futhark, Younger Futhark, and Tolkien-inspired Cirth. The app ships both direct transliteration and an offline, evidence-backed historical translation flow, plus a WidgetKit extension that stays transliteration-first.

## Current Baseline

- Platform: iOS 26.0+
- Toolchain: Xcode 26.3, Swift 6.2
- UI: SwiftUI + WidgetKit
- Storage: SwiftData
- DI: Needle + generated components
- Build config: XcodeGen via `project.yml`
- Translation data: bundled offline JSON curated in `TranslationCuration/`

## Quick Start

```bash
brew install xcodegen needle swiftlint swiftformat

xcodegen generate
./scripts/generate-needle.sh

swift build
swift test
swiftlint lint --strict
swiftformat --lint .

open RunicQuotes.xcodeproj
```

For a simulator build from the CLI:

```bash
xcodebuild -scheme RunicQuotes \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' \
  build
```

## What Ships

- Direct transliteration for Elder Futhark, Younger Futhark, and Cirth
- Historical translation mode with strict, readable, and decorative fidelity
- Evidence tiers, provenance, token breakdowns, and source-language guidance
- Home and Share surfaces that prefer cached structured translations when available
- Home Screen and Lock Screen widgets backed by the shared SwiftData store
- Three bundled runic fonts and theme-driven SwiftUI presentation

## Repository Layout

```text
RunicQuotes/
  App/                app entry, lifecycle, entitlements
  Data/               repositories, actors, translation/transliteration engines
  DI/                 Needle components and generated wiring
  Models/             SwiftData models, DTOs, enums
  Resources/          fonts, seed data, localization, translation assets
  Utilities/          themes, logging, helpers
  ViewModels/         screen state and orchestration
  Views/              SwiftUI screens and reusable components

RunicQuotesWidget/    WidgetKit extension, timeline provider, widget views
RunicQuotesTests/     package and unit tests
RunicQuotesUITests/   UI coverage for navigation and translation flows
RunicQuotesWidgetTests/
TranslationCuration/  source-of-truth translation dataset
scripts/              project and asset generation helpers
```

## Documentation

- [docs/PROJECT_OVERVIEW.md](docs/PROJECT_OVERVIEW.md): architecture, targets, and workflow map
- [XCODE_SETUP.md](XCODE_SETUP.md): local setup, generators, and troubleshooting
- [WIDGET_SETUP.md](WIDGET_SETUP.md): widget architecture and shared-data behavior
- [PERFORMANCE.md](PERFORMANCE.md): performance goals and runtime strategies
- [docs/translation/IOS_IMPLEMENTATION.md](docs/translation/IOS_IMPLEMENTATION.md): iOS translation runtime and UI behavior
- [docs/translation/IMPLEMENTED_ARCHITECTURE.md](docs/translation/IMPLEMENTED_ARCHITECTURE.md): translation stack architecture
- [docs/translation/CURATION_POLICY.md](docs/translation/CURATION_POLICY.md): curation schema, export flow, and validation rules
- [docs/translation/FUTURE_RESEARCH.md](docs/translation/FUTURE_RESEARCH.md): next research and coverage-expansion backlog
- [TranslationCuration/README.md](TranslationCuration/README.md): source-of-truth dataset package and mirror export process

## Dependency Injection

- Runtime DI uses [Needle](https://github.com/uber/needle) `0.25.1`.
- Generated files live in `RunicQuotes/DI/App/AppNeedleGenerated.swift` and `RunicQuotesWidget/DI/WidgetNeedleGenerated.swift`.
- Regenerate them with `./scripts/generate-needle.sh` after changing any `Component` or `Dependency` declaration.
