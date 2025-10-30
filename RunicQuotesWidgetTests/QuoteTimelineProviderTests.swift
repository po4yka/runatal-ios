//
//  QuoteTimelineProviderTests.swift
//  RunicQuotesWidgetTests
//
//  Created by Claude on 2025-11-15.
//

import XCTest
import WidgetKit
import SwiftData
@testable import RunicQuotesWidget
@testable import RunicQuotes

final class QuoteTimelineProviderTests: XCTestCase {
    var provider: QuoteTimelineProvider!

    override func setUpWithError() throws {
        provider = QuoteTimelineProvider()
    }

    override func tearDownWithError() throws {
        provider = nil
    }

    // MARK: - Placeholder Tests

    func testPlaceholderReturnsEntry() {
        // When: Requesting placeholder
        let context = createContext(family: .systemSmall)
        let entry = provider.placeholder(in: context)

        // Then: Should return valid entry
        XCTAssertNotNil(entry, "Placeholder should return entry")
        XCTAssertFalse(entry.quote.textLatin.isEmpty, "Placeholder should have text")
        XCTAssertFalse(entry.quote.author.isEmpty, "Placeholder should have author")
    }

    func testPlaceholderHasAllScripts() {
        // When: Requesting placeholder
        let context = createContext(family: .systemSmall)
        let entry = provider.placeholder(in: context)

        // Then: Should have all runic scripts
        XCTAssertNotNil(entry.quote.runicElder, "Placeholder should have Elder Futhark")
        XCTAssertNotNil(entry.quote.runicYounger, "Placeholder should have Younger Futhark")
        XCTAssertNotNil(entry.quote.runicCirth, "Placeholder should have Cirth")
    }

    // MARK: - Snapshot Tests

    func testSnapshotReturnsEntry() {
        // Given: Context
        let context = createContext(family: .systemMedium)
        let expectation = XCTestExpectation(description: "Snapshot completion")

        // When: Requesting snapshot
        provider.getSnapshot(in: context) { entry in
            // Then: Should return entry
            XCTAssertNotNil(entry, "Snapshot should return entry")
            XCTAssertFalse(entry.quote.textLatin.isEmpty, "Snapshot should have text")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Timeline Tests

    func testTimelineReturnsEntries() {
        // Given: Context
        let context = createContext(family: .systemSmall)
        let expectation = XCTestExpectation(description: "Timeline completion")

        // When: Requesting timeline
        provider.getTimeline(in: context) { timeline in
            // Then: Should return timeline with entries
            XCTAssertFalse(timeline.entries.isEmpty, "Timeline should have entries")
            XCTAssertGreaterThan(timeline.entries.count, 0, "Should have at least one entry")

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testTimelineEntriesAreOrdered() {
        // Given: Context
        let context = createContext(family: .systemLarge)
        let expectation = XCTestExpectation(description: "Timeline completion")

        // When: Requesting timeline
        provider.getTimeline(in: context) { timeline in
            // Then: Entries should be ordered by date
            let entries = timeline.entries
            if entries.count > 1 {
                for i in 0..<(entries.count - 1) {
                    XCTAssertLessThanOrEqual(
                        entries[i].date,
                        entries[i + 1].date,
                        "Timeline entries should be ordered by date"
                    )
                }
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testTimelineHasRefreshPolicy() {
        // Given: Context
        let context = createContext(family: .systemSmall)
        let expectation = XCTestExpectation(description: "Timeline completion")

        // When: Requesting timeline
        provider.getTimeline(in: context) { timeline in
            // Then: Should have refresh policy
            // Policy is .atEnd which means refresh after last entry
            XCTAssertNotNil(timeline.policy, "Timeline should have refresh policy")

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Widget Family Support Tests

    func testSupportsAllWidgetFamilies() {
        let families: [WidgetFamily] = [
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ]

        for family in families {
            let context = createContext(family: family)
            let entry = provider.placeholder(in: context)

            XCTAssertNotNil(entry, "Should support \(family)")
        }
    }

    // MARK: - Entry Content Tests

    func testEntryHasValidQuoteData() {
        // Given: Context
        let context = createContext(family: .systemMedium)
        let expectation = XCTestExpectation(description: "Timeline completion")

        // When: Requesting timeline
        provider.getTimeline(in: context) { timeline in
            guard let entry = timeline.entries.first else {
                XCTFail("Timeline should have at least one entry")
                return
            }

            // Then: Entry should have valid quote data
            XCTAssertFalse(entry.quote.textLatin.isEmpty, "Entry should have Latin text")
            XCTAssertFalse(entry.quote.author.isEmpty, "Entry should have author")
            XCTAssertNotNil(entry.quote.runicText(for: entry.script), "Entry should have runic text for selected script")

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testEntryHasValidScript() {
        // Given: Context
        let context = createContext(family: .systemSmall)
        let expectation = XCTestExpectation(description: "Timeline completion")

        // When: Requesting timeline
        provider.getTimeline(in: context) { timeline in
            guard let entry = timeline.entries.first else {
                XCTFail("Timeline should have at least one entry")
                return
            }

            // Then: Entry should have valid script
            let validScripts: [RunicScript] = [.elder, .younger, .cirth]
            XCTAssertTrue(validScripts.contains(entry.script), "Entry should have valid script")

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Error Handling Tests

    func testTimelineHandlesErrorsGracefully() {
        // Test with minimal context to potentially trigger errors
        let context = createContext(family: .systemSmall)
        let expectation = XCTestExpectation(description: "Timeline completion")

        // When: Requesting timeline
        provider.getTimeline(in: context) { timeline in
            // Then: Should return timeline even if there are errors
            // (Should fallback to placeholder)
            XCTAssertNotNil(timeline, "Timeline should not be nil even on error")
            XCTAssertFalse(timeline.entries.isEmpty, "Timeline should have at least fallback entry")

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    // MARK: - Performance Tests

    func testPlaceholderPerformance() {
        measure {
            let context = createContext(family: .systemSmall)
            _ = provider.placeholder(in: context)
        }
    }

    func testSnapshotPerformance() {
        measure {
            let context = createContext(family: .systemMedium)
            let expectation = XCTestExpectation(description: "Snapshot")

            provider.getSnapshot(in: context) { _ in
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 2.0)
        }
    }

    // MARK: - Helper Methods

    private func createContext(family: WidgetFamily) -> MockWidgetContext {
        MockWidgetContext(family: family)
    }
}

// MARK: - Mock Context

class MockWidgetContext: TimelineProviderContext {
    let family: WidgetFamily
    let isPreview: Bool
    let displaySize: CGSize

    init(family: WidgetFamily, isPreview: Bool = false) {
        self.family = family
        self.isPreview = isPreview

        // Approximate display sizes for each family
        switch family {
        case .systemSmall:
            self.displaySize = CGSize(width: 155, height: 155)
        case .systemMedium:
            self.displaySize = CGSize(width: 329, height: 155)
        case .systemLarge:
            self.displaySize = CGSize(width: 329, height: 345)
        case .accessoryCircular:
            self.displaySize = CGSize(width: 50, height: 50)
        case .accessoryRectangular:
            self.displaySize = CGSize(width: 157, height: 50)
        case .accessoryInline:
            self.displaySize = CGSize(width: 200, height: 20)
        default:
            self.displaySize = CGSize(width: 155, height: 155)
        }
    }

    var environmentVariants: EnvironmentVariants {
        EnvironmentVariants()
    }
}
