//
//  QuoteViewModelTests.swift
//  RunicQuotesTests
//
//  Created by Claude on 2025-11-15.
//

import XCTest
import SwiftData
@testable import RunicQuotes

final class QuoteViewModelTests: XCTestCase {
    // MARK: - Initialization Tests

    @MainActor
    func testInitialState() throws {
        let viewModel = try makeViewModel()

        XCTAssertTrue(viewModel.state.isLoading, "Should start in loading state")
        XCTAssertEqual(viewModel.state.runicText, "", "Runic text should be empty initially")
        XCTAssertEqual(viewModel.state.latinText, "", "Latin text should be empty initially")
        XCTAssertEqual(viewModel.state.author, "", "Author should be empty initially")
    }

    @MainActor
    func testDefaultScript() throws {
        let viewModel = try makeViewModel()
        XCTAssertEqual(viewModel.state.currentScript, .elder, "Default script should be Elder Futhark")
    }

    @MainActor
    func testDefaultFont() throws {
        let viewModel = try makeViewModel()
        XCTAssertEqual(viewModel.state.currentFont, .noto, "Default font should be Noto")
    }

    // MARK: - Loading Tests

    @MainActor
    func testOnAppearLoadsQuote() async throws {
        let viewModel = try makeViewModel()
        viewModel.onAppear()

        await waitUntil("view model finishes loading") {
            !viewModel.state.isLoading
        }

        XCTAssertFalse(viewModel.state.isLoading, "Should finish loading")
        XCTAssertFalse(viewModel.state.latinText.isEmpty, "Should load Latin text")
        XCTAssertFalse(viewModel.state.author.isEmpty, "Should load author")
    }

    @MainActor
    func testLoadedQuoteHasRunicText() async throws {
        let viewModel = try makeViewModel()
        viewModel.onAppear()

        await waitUntil("quote loads") {
            !viewModel.state.isLoading
        }

        XCTAssertFalse(viewModel.state.runicText.isEmpty, "Should have runic text")
        XCTAssertNotEqual(
            viewModel.state.runicText,
            viewModel.state.latinText,
            "Runic text should differ from Latin text"
        )
    }

    // MARK: - Script Switching Tests

    @MainActor
    func testScriptChangeUpdatesState() async throws {
        let viewModel = try makeViewModel()
        viewModel.onAppear()

        await waitUntil("initial quote loads") {
            !viewModel.state.isLoading
        }

        viewModel.onScriptChanged(.younger)

        await waitUntil("script switches to younger") {
            viewModel.state.currentScript == .younger && !viewModel.state.isLoading
        }

        XCTAssertEqual(viewModel.state.currentScript, .younger, "Script should change to Younger")
    }

    @MainActor
    func testScriptChangeReloadsQuote() async throws {
        let viewModel = try makeViewModel()
        viewModel.onAppear()

        await waitUntil("initial quote loads") {
            !viewModel.state.isLoading
        }

        let originalText = viewModel.state.latinText
        viewModel.onScriptChanged(.cirth)

        await waitUntil("script switches to cirth and reload completes") {
            viewModel.state.currentScript == .cirth && !viewModel.state.isLoading
        }

        XCTAssertFalse(viewModel.state.latinText.isEmpty, "Should have Latin text after script change")
        XCTAssertNotEqual(originalText, "", "Original quote should not be empty")
    }

    // MARK: - Font Change Tests

    @MainActor
    func testFontChangeUpdatesState() async throws {
        let viewModel = try makeViewModel()
        viewModel.onAppear()

        await waitUntil("initial quote loads") {
            !viewModel.state.isLoading
        }

        viewModel.onFontChanged(.babelstone)

        await waitUntil("font switches to BabelStone") {
            viewModel.state.currentFont == .babelstone
        }

        XCTAssertEqual(viewModel.state.currentFont, .babelstone, "Font should change to BabelStone")
    }

    @MainActor
    func testFontCompatibilityCheck() async throws {
        let viewModel = try makeViewModel()
        viewModel.onScriptChanged(.cirth)

        await waitUntil("script switches to cirth") {
            viewModel.state.currentScript == .cirth && !viewModel.state.isLoading
        }

        viewModel.onFontChanged(.noto)

        await waitUntil("font compatibility check completes") {
            viewModel.state.errorMessage != nil || viewModel.state.currentFont != .noto
        }

        if viewModel.state.errorMessage != nil {
            XCTAssertTrue(
                viewModel.state.errorMessage!.contains("compatible"),
                "Error should mention compatibility"
            )
        }
    }

    // MARK: - Next Quote Tests

    @MainActor
    func testNextQuoteTappedLoadsQuote() async throws {
        let viewModel = try makeViewModel()
        viewModel.onAppear()

        await waitUntil("initial quote loads") {
            !viewModel.state.isLoading
        }

        viewModel.onNextQuoteTapped()

        await waitUntil("next quote load completes with content") {
            !viewModel.state.isLoading && !viewModel.state.latinText.isEmpty && !viewModel.state.author.isEmpty
        }

        XCTAssertFalse(viewModel.state.latinText.isEmpty, "Should have Latin text after tapping next quote")
        XCTAssertFalse(viewModel.state.author.isEmpty, "Should have author after tapping next quote")
    }

    // MARK: - Refresh Tests

    @MainActor
    func testRefreshReloadsQuote() async throws {
        let viewModel = try makeViewModel()
        viewModel.onAppear()

        await waitUntil("initial quote loads") {
            !viewModel.state.isLoading
        }

        viewModel.refresh()

        await waitUntil("refresh completes") {
            !viewModel.state.isLoading
        }

        XCTAssertFalse(viewModel.state.latinText.isEmpty, "Should have quote after refresh")
        XCTAssertNil(viewModel.state.errorMessage, "Should not have error after successful refresh")
    }

    // MARK: - Error Handling Tests

    @MainActor
    func testErrorStateWhenNoQuotes() async throws {
        let viewModel = try makeViewModel(seedData: false)
        viewModel.onAppear()

        await waitUntil("error state is populated") {
            !viewModel.state.isLoading && viewModel.state.errorMessage != nil
        }

        XCTAssertNotNil(viewModel.state.errorMessage, "Should have error message")
        XCTAssertFalse(viewModel.state.isLoading, "Should not be loading")
    }

    // MARK: - State Consistency Tests

    @MainActor
    func testStateConsistencyAfterMultipleOperations() async throws {
        let viewModel = try makeViewModel()
        viewModel.onAppear()

        await waitUntil("initial quote loads") {
            !viewModel.state.isLoading
        }

        viewModel.onScriptChanged(.younger)
        await waitUntil("script switches to younger") {
            viewModel.state.currentScript == .younger && !viewModel.state.isLoading
        }

        viewModel.onFontChanged(.babelstone)
        await waitUntil("font switches to BabelStone") {
            viewModel.state.currentFont == .babelstone
        }

        viewModel.onNextQuoteTapped()
        await waitUntil("next quote load completes") {
            !viewModel.state.isLoading
        }

        XCTAssertEqual(viewModel.state.currentScript, .younger, "Script should be Younger")
        XCTAssertEqual(viewModel.state.currentFont, .babelstone, "Font should be BabelStone")
        XCTAssertFalse(viewModel.state.latinText.isEmpty, "Should have quote text")
    }

    // MARK: - Helpers

    @MainActor
    private func makeViewModel(seedData: Bool = true) throws -> QuoteViewModel {
        let schema = Schema([Quote.self, UserPreferences.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: schema, configurations: config)
        let modelContext = ModelContext(modelContainer)

        if seedData {
            let repository = SwiftDataQuoteRepository(modelContext: modelContext)
            try repository.seedIfNeeded()
        }

        return QuoteViewModel(modelContext: modelContext)
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
            if condition() {
                return
            }

            try? await Task.sleep(nanoseconds: pollIntervalNanoseconds)
        }

        XCTFail("Timed out waiting for condition: \(description)")
    }
}
