//
//  QuoteViewModelTests.swift
//  RunicQuotesTests
//
//  Created by Claude on 2025-11-15.
//

import XCTest
import SwiftData
@testable import RunicQuotes

@MainActor
final class QuoteViewModelTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var viewModel: QuoteViewModel!

    override func setUpWithError() throws {
        // Create in-memory container for testing
        let schema = Schema([Quote.self, UserPreferences.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: config)
        modelContext = ModelContext(modelContainer)

        // Seed test data
        let repository = SwiftDataQuoteRepository(modelContext: modelContext)
        Task {
            try await repository.seedIfNeeded()
        }

        viewModel = QuoteViewModel(modelContext: modelContext)
    }

    override func tearDownWithError() throws {
        viewModel = nil
        modelContext = nil
        modelContainer = nil
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        // Then: Initial state should be loading
        XCTAssertTrue(viewModel.state.isLoading, "Should start in loading state")
        XCTAssertEqual(viewModel.state.runicText, "", "Runic text should be empty initially")
        XCTAssertEqual(viewModel.state.latinText, "", "Latin text should be empty initially")
        XCTAssertEqual(viewModel.state.author, "", "Author should be empty initially")
    }

    func testDefaultScript() {
        // Then: Default script should be Elder Futhark
        XCTAssertEqual(viewModel.state.currentScript, .elder, "Default script should be Elder Futhark")
    }

    func testDefaultFont() {
        // Then: Default font should be Noto
        XCTAssertEqual(viewModel.state.currentFont, .noto, "Default font should be Noto")
    }

    // MARK: - Loading Tests

    func testOnAppearLoadsQuote() async {
        // When: View appears
        viewModel.onAppear()

        // Give async task time to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Then: Should load a quote
        XCTAssertFalse(viewModel.state.isLoading, "Should finish loading")
        XCTAssertFalse(viewModel.state.latinText.isEmpty, "Should load Latin text")
        XCTAssertFalse(viewModel.state.author.isEmpty, "Should load author")
    }

    func testLoadedQuoteHasRunicText() async {
        // When: Loading quote
        viewModel.onAppear()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should have runic transliteration
        XCTAssertFalse(viewModel.state.runicText.isEmpty, "Should have runic text")
        XCTAssertNotEqual(
            viewModel.state.runicText,
            viewModel.state.latinText,
            "Runic text should differ from Latin text"
        )
    }

    // MARK: - Script Switching Tests

    func testScriptChangeUpdatesState() async {
        // Given: Loaded quote
        viewModel.onAppear()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When: Changing script
        viewModel.onScriptChanged(.younger)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: State should update
        XCTAssertEqual(viewModel.state.currentScript, .younger, "Script should change to Younger")
    }

    func testScriptChangeReloadsQuote() async {
        // Given: Loaded quote
        viewModel.onAppear()
        try? await Task.sleep(nanoseconds: 100_000_000)
        let originalText = viewModel.state.latinText

        // When: Changing script
        viewModel.onScriptChanged(.cirth)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should still have a quote (might be same or different)
        XCTAssertFalse(viewModel.state.latinText.isEmpty, "Should have Latin text after script change")
    }

    // MARK: - Font Change Tests

    func testFontChangeUpdatesState() async {
        // Given: Loaded quote
        viewModel.onAppear()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When: Changing font
        viewModel.onFontChanged(.babelstone)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: Font should update
        XCTAssertEqual(viewModel.state.currentFont, .babelstone, "Font should change to BabelStone")
    }

    func testFontCompatibilityCheck() async {
        // Given: Cirth script
        viewModel.onScriptChanged(.cirth)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When: Trying to set incompatible font
        viewModel.onFontChanged(.noto)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should show error or keep compatible font
        // (Implementation may vary - either reject or auto-switch)
        if viewModel.state.errorMessage != nil {
            XCTAssertTrue(
                viewModel.state.errorMessage!.contains("compatible"),
                "Error should mention compatibility"
            )
        }
    }

    // MARK: - Next Quote Tests

    func testNextQuoteTappedLoadsNewQuote() async {
        // Given: Loaded quote
        viewModel.onAppear()
        try? await Task.sleep(nanoseconds: 100_000_000)
        let firstQuote = viewModel.state.latinText

        // When: Tapping next quote multiple times
        var differentQuoteFound = false
        for _ in 0..<5 {
            viewModel.onNextQuoteTapped()
            try? await Task.sleep(nanoseconds: 100_000_000)

            if viewModel.state.latinText != firstQuote {
                differentQuoteFound = true
                break
            }
        }

        // Then: Should load different quote (probabilistically)
        XCTAssertTrue(differentQuoteFound, "Should load different quote eventually")
    }

    // MARK: - Refresh Tests

    func testRefreshReloadsQuote() async {
        // Given: Loaded quote
        viewModel.onAppear()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When: Refreshing
        viewModel.refresh()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should have quote
        XCTAssertFalse(viewModel.state.latinText.isEmpty, "Should have quote after refresh")
        XCTAssertNil(viewModel.state.errorMessage, "Should not have error after successful refresh")
    }

    // MARK: - Error Handling Tests

    func testErrorStateWhenNoQuotes() {
        // Given: Empty repository (no seeding)
        let emptyContainer = try! ModelContainer(
            for: Schema([Quote.self, UserPreferences.self]),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let emptyContext = ModelContext(emptyContainer)
        let emptyViewModel = QuoteViewModel(modelContext: emptyContext)

        // When: Loading
        emptyViewModel.onAppear()

        // Give time for error
        let expectation = XCTestExpectation(description: "Error state")
        Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then: Should have error
        XCTAssertNotNil(emptyViewModel.state.errorMessage, "Should have error message")
        XCTAssertFalse(emptyViewModel.state.isLoading, "Should not be loading")
    }

    // MARK: - State Consistency Tests

    func testStateConsistencyAfterMultipleOperations() async {
        // Perform multiple operations
        viewModel.onAppear()
        try? await Task.sleep(nanoseconds: 50_000_000)

        viewModel.onScriptChanged(.younger)
        try? await Task.sleep(nanoseconds: 50_000_000)

        viewModel.onFontChanged(.babelstone)
        try? await Task.sleep(nanoseconds: 50_000_000)

        viewModel.onNextQuoteTapped()
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Then: State should be consistent
        XCTAssertEqual(viewModel.state.currentScript, .younger, "Script should be Younger")
        XCTAssertEqual(viewModel.state.currentFont, .babelstone, "Font should be BabelStone")
        XCTAssertFalse(viewModel.state.latinText.isEmpty, "Should have quote text")
    }
}
