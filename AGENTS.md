# RunicQuotes — Agent Context

SwiftUI iOS app for runic script quotes with WidgetKit extension.

## Stack

Swift 6.1 | iOS 17+ | SwiftUI + SwiftData + WidgetKit | strict concurrency | zero deps

## Architecture

- MVVM + Repository + Actor
- ViewModels: `@MainActor final class`, `@Published private(set) var state` (Sendable struct)
- `QuoteRepository` protocol -> `SwiftDataQuoteRepository`
- `QuoteProvider` actor for thread-safe access
- `QuoteRecord` Sendable DTO for cross-boundary data

## Build / Test / Lint

```bash
xcodegen generate
swift build
swift test
xcodebuild -scheme RunicQuotes build
swiftlint lint --strict
swiftformat --lint .
```

## Directory Map

```
RunicQuotes/
  App/          Models/       Data/         ViewModels/
  Views/        Utilities/    Resources/
RunicQuotesWidget/
RunicQuotesTests/   # mirrors source path
```

## Key Conventions

- `// MARK: - Section` to organize types
- `os.Logger` only — no `print()`
- Enums: `String, Codable, CaseIterable, Identifiable, Sendable`
- UI: `GlassCard`, `GlassButton`, `AppThemePalette` for colors
- ViewModels: `static func preview()`; Models: `static var sample`
- Tests: in-memory `ModelContainer`, `makeViewModel(seedData:)`, `waitUntil` helper
- Test naming: `test<Behavior><Expected>`
- `@MainActor` on all test methods touching ViewModels/ModelContext

## Domain

3 scripts (Elder Futhark, Younger Futhark, Cirth), 4 collections (All, Motivation, Stoic, Tolkien), `RunicTransliterator`

## Before Submitting

- [ ] `swiftlint lint --strict` passes
- [ ] `swiftformat --lint .` passes
- [ ] `swift test` passes
- [ ] No strict concurrency warnings
- [ ] Test file mirrors source path

## Skills

See `.agents/skills/` for available skills: `runatal-scaffold`, `runatal-test-gen`, `swiftui-pro`.
