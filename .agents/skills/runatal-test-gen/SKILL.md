---
name: runatal-test-gen
description: >
  Use when the user asks to add tests for a ViewModel, repository, or data type
  in RunicQuotes. Generates unit tests following established patterns from
  QuoteViewModelTests.swift. Don't use for UI tests or widget tests.
disable-model-invocation: true
---

# Generate Unit Tests

Generate tests for existing RunicQuotes types matching the project's established patterns.

## Test File Template

```swift
//
//  <Type>Tests.swift
//  RunicQuotesTests
//

import XCTest
import SwiftData
@testable import RunicQuotes

final class <Type>Tests: XCTestCase {
    // MARK: - Initialization

    // MARK: - <Behavior Group>

    // MARK: - Helpers

    @MainActor
    private func makeViewModel(seedData: Bool = true) throws -> <Type> {
        let schema = Schema([Quote.self, UserPreferences.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: schema, configurations: config)
        let modelContext = ModelContext(modelContainer)

        if seedData {
            let repository = SwiftDataQuoteRepository(modelContext: modelContext)
            try repository.seedIfNeeded()
        }

        return <Type>(modelContext: modelContext)
    }

    @MainActor
    private func waitUntil(
        _ description: String,
        timeoutNanoseconds: UInt64 = 2_000_000_000,
        pollIntervalNanoseconds: UInt64 = 25_000_000,
        condition: () -> Bool
    ) async {
        let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds
        while DispatchTime.now().uptimeNanoseconds < deadline {
            if condition() { return }
            try? await Task.sleep(nanoseconds: pollIntervalNanoseconds)
        }
        XCTFail("Timed out waiting for condition: \(description)")
    }
}
```

## Conventions

| Rule | Pattern |
|------|---------|
| **Naming** | `test<Behavior><Expected>` (e.g., `testOnAppearLoadsQuote`) |
| **MARK sections** | Initialization, Loading, behavior groups, Helpers |
| **Actor isolation** | `@MainActor` on all methods touching ViewModel/ModelContext |
| **Container** | In-memory `ModelContainer` via `makeViewModel` factory |
| **Async polling** | `waitUntil` helper for async state changes |
| **File path** | Mirrors source: `ViewModels/FooVM.swift` -> `RunicQuotesTests/ViewModels/FooVMTests.swift` |
| **Imports** | `import XCTest`, `import SwiftData`, `@testable import RunicQuotes` |

## What to Test

For **ViewModels**:
- Initial state values (isLoading, defaults)
- `onAppear()` loads data and updates state
- Each public method's effect on state
- Error paths (empty data, missing preferences)
- Script/font/collection switching

For **Repositories**:
- `seedIfNeeded()` populates data
- CRUD operations
- Query filtering by collection/script

For **Data types** (enums, DTOs):
- All cases exist and have expected raw values
- `Codable` round-trip encoding/decoding
- Computed properties return expected values
- `CaseIterable.allCases` count

## Example: Testing a ViewModel Method

```swift
@MainActor
func testChangeScriptUpdatesState() throws {
    let viewModel = try makeViewModel()
    viewModel.onAppear()

    await waitUntil("initial load") {
        !viewModel.state.isLoading
    }

    viewModel.changeScript(.younger)

    XCTAssertEqual(viewModel.state.currentScript, .younger)
    XCTAssertFalse(viewModel.state.runicText.isEmpty, "Should re-transliterate")
}
```

## Checklist

After generating tests:
- [ ] All test methods are `@MainActor` if they touch ViewModel/ModelContext
- [ ] `makeViewModel` factory uses in-memory container
- [ ] `waitUntil` helper is present for async tests
- [ ] Test file path mirrors source path
- [ ] `swift test` passes
- [ ] No strict concurrency warnings
