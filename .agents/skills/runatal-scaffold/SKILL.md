---
name: runatal-scaffold
description: >
  Use when creating a new screen, component, or feature module in RunicQuotes.
  Scaffolds Model, ViewModel, View, and Test files following project conventions.
  Don't use for modifying existing files.
disable-model-invocation: true
---

# Scaffold New Feature

Generate files for a new RunicQuotes feature following exact project conventions.

## What to Generate

Given a feature name (e.g., `Bookmark`), create these files:

### 1. Enum Model — `RunicQuotes/Models/Enums/<Name>.swift`

```swift
//
//  <Name>.swift
//  RunicQuotes
//

import Foundation

/// <Description>
enum <Name>: String, Codable, CaseIterable, Identifiable, Sendable {
    case <value1> = "<Display 1>"
    case <value2> = "<Display 2>"

    var id: String { rawValue }

    var displayName: String { rawValue }
}
```

### 2. ViewModel — `RunicQuotes/ViewModels/<Name>ViewModel.swift`

```swift
//
//  <Name>ViewModel.swift
//  RunicQuotes
//

import Foundation
import SwiftUI
import SwiftData

/// UI state for the <name> view
struct <Name>UiState: Sendable {
    var isLoading: Bool = true
    var errorMessage: String?
}

/// ViewModel for <name> screen
@MainActor
final class <Name>ViewModel: ObservableObject {
    // MARK: - Published State

    @Published private(set) var state = <Name>UiState()

    // MARK: - Dependencies

    private var modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public API

    func onAppear() {
        Task {
            await load()
        }
    }

    // MARK: - Private

    private func load() async {
        state.isLoading = false
    }

    // MARK: - Preview Support

    static func preview() -> <Name>ViewModel {
        let container = ModelContainerHelper.createPlaceholderContainer()
        return <Name>ViewModel(modelContext: ModelContext(container))
    }
}
```

### 3. View — `RunicQuotes/Views/<Name>View.swift`

```swift
//
//  <Name>View.swift
//  RunicQuotes
//

import SwiftUI
import SwiftData

/// <Description> view
struct <Name>View: View {
    // MARK: - Properties

    @StateObject private var viewModel: <Name>ViewModel
    @Environment(\.modelContext) private var modelContext

    // MARK: - Initialization

    init() {
        let placeholderContainer = ModelContainerHelper.createPlaceholderContainer()
        _viewModel = StateObject(wrappedValue: <Name>ViewModel(
            modelContext: ModelContext(placeholderContainer)
        ))
    }

    // MARK: - Body

    var body: some View {
        GlassCard {
            if viewModel.state.isLoading {
                ProgressView()
            } else {
                contentView
            }
        }
        .task {
            viewModel.configureIfNeeded(modelContext: modelContext)
            viewModel.onAppear()
        }
    }

    // MARK: - Subviews

    private var contentView: some View {
        Text("<Name>")
    }
}

#Preview {
    <Name>View()
}
```

### 4. Test — `RunicQuotesTests/ViewModels/<Name>ViewModelTests.swift`

```swift
//
//  <Name>ViewModelTests.swift
//  RunicQuotesTests
//

import XCTest
import SwiftData
@testable import RunicQuotes

final class <Name>ViewModelTests: XCTestCase {
    // MARK: - Initialization

    @MainActor
    func testInitialStateIsLoading() throws {
        let viewModel = try makeViewModel()
        XCTAssertTrue(viewModel.state.isLoading)
    }

    // MARK: - Loading

    @MainActor
    func testOnAppearCompletesLoading() throws {
        let viewModel = try makeViewModel()
        viewModel.onAppear()

        await waitUntil("loading completes") {
            !viewModel.state.isLoading
        }
    }

    // MARK: - Helpers

    @MainActor
    private func makeViewModel(seedData: Bool = true) throws -> <Name>ViewModel {
        let schema = Schema([Quote.self, UserPreferences.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: schema, configurations: config)
        let modelContext = ModelContext(modelContainer)

        if seedData {
            let repository = SwiftDataQuoteRepository(modelContext: modelContext)
            try repository.seedIfNeeded()
        }

        return <Name>ViewModel(modelContext: modelContext)
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

## Checklist

After scaffolding, verify:
- [ ] All files use correct file header (filename, target)
- [ ] ViewModel is `@MainActor final class` with Sendable state struct
- [ ] View uses `@StateObject` + placeholder init pattern
- [ ] Test uses in-memory `ModelContainer` and `@MainActor`
- [ ] File paths match project directory conventions
- [ ] `swift build` succeeds
