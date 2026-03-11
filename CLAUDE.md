# RunicQuotes — Project Context

SwiftUI iOS app for displaying quotes in runic scripts (Elder Futhark, Younger Futhark, Cirth). Includes a WidgetKit extension.

## Stack

- SwiftUI, SwiftData, WidgetKit
- Swift 6.1, iOS 17+, strict concurrency
- Zero third-party dependencies

## Architecture

MVVM + Repository + Actor-based concurrency:

- **ViewModels**: `@MainActor final class`, `@Published private(set) var state` with Sendable state struct
- **Repository**: `QuoteRepository` protocol -> `SwiftDataQuoteRepository`
- **Actor**: `QuoteProvider` for thread-safe quote access
- **DTO**: `QuoteRecord` (Sendable) for cross-boundary data

## Build & Lint

```bash
xcodegen generate                    # Regenerate Xcode project
swift build                          # Build
swift test                           # Run tests
xcodebuild -scheme RunicQuotes build # Full Xcode build
swiftlint lint --strict              # Lint
swiftformat --lint .                 # Format check
```

## Directory Map

```
RunicQuotes/
  App/            # App entry point, ModelContainer setup
  Models/         # SwiftData models, Enums/
  Data/           # Repository protocol + SwiftData implementation
  ViewModels/     # @MainActor ObservableObject classes
  Views/          # SwiftUI views, components
  Utilities/      # RunicTransliterator, helpers
  Resources/      # Assets, JSON seed data, fonts
RunicQuotesWidget/  # WidgetKit extension
RunicQuotesTests/   # Unit tests (mirrors source path)
```

## Conventions

- **File headers**: standard Xcode template (filename, target, date)
- **MARK sections**: `// MARK: - Section Name` to organize types
- **Logging**: `os.Logger` only — no `print()`
- **Enums**: `String, Codable, CaseIterable, Identifiable, Sendable`
- **UI components**: `GlassCard`, `GlassButton` for glass morphism
- **Colors**: `AppThemePalette` — never hardcode colors
- **Previews**: `static func preview()` on ViewModels, `#Preview` on Views
- **Sample data**: `static var sample` on model types

## Testing Patterns

- In-memory `ModelContainer(for: Schema([Quote.self, UserPreferences.self]))` with `isStoredInMemoryOnly: true`
- `makeViewModel(seedData:)` factory in each test class
- `waitUntil(_:timeoutNanoseconds:pollIntervalNanoseconds:condition:)` async polling helper
- `@MainActor` on all test methods touching ViewModels or ModelContext
- Test file placement mirrors source path: `ViewModels/FooVM.swift` -> `RunicQuotesTests/ViewModels/FooVMTests.swift`
- Test naming: `test<Behavior><Expected>` (e.g., `testOnAppearLoadsQuote`)

## Domain

- 3 runic scripts: Elder Futhark, Younger Futhark, Cirth
- 4 collections: All, Motivation, Stoic, Tolkien
- `RunicTransliterator` converts Latin text to runic glyphs

## Skills

Custom skills in `.agents/skills/`:
- `runatal-scaffold` — scaffold new features
- `runatal-test-gen` — generate unit tests
- `swiftui-pro` — SwiftUI code review (third-party)
