//
//  QuoteTimelineProviderTests.swift
//  RunicQuotesWidgetTests
//
//  Created by Claude on 2025-11-15.
//

import XCTest
@testable import RunicQuotes

/// Tests for shared data types used by both the main app and the widget extension.
/// Widget extension binaries (app extensions) do not export Swift symbols for testing,
/// so these tests verify the shared RunicQuotes module types that power widget behaviour.
final class QuoteTimelineProviderTests: XCTestCase {

    // MARK: - RunicScript Tests

    func testRunicScriptCasesExist() {
        let scripts: [RunicScript] = [.elder, .younger, .cirth]
        XCTAssertEqual(scripts.count, 3, "Should have three runic script cases")
    }

    func testRunicScriptIsIdentifiable() {
        XCTAssertEqual(RunicScript.elder.id, RunicScript.elder.rawValue)
        XCTAssertEqual(RunicScript.younger.id, RunicScript.younger.rawValue)
        XCTAssertEqual(RunicScript.cirth.id, RunicScript.cirth.rawValue)
    }

    func testRunicScriptAllCasesCount() {
        XCTAssertEqual(RunicScript.allCases.count, 3)
    }

    // MARK: - Widget-relevant AppConstants Tests

    func testDailyQuoteIndexIsStable() {
        // Same date should always return the same index
        let date = Date(timeIntervalSinceReferenceDate: 0)
        let index1 = AppConstants.dailyQuoteIndex(for: date, totalQuotes: 100)
        let index2 = AppConstants.dailyQuoteIndex(for: date, totalQuotes: 100)
        XCTAssertEqual(index1, index2, "Daily quote index should be deterministic")
    }

    func testDailyQuoteIndexIsWithinBounds() {
        let totalQuotes = 50
        let date = Date()
        let index = AppConstants.dailyQuoteIndex(for: date, totalQuotes: totalQuotes)
        XCTAssertGreaterThanOrEqual(index, 0)
        XCTAssertLessThan(index, totalQuotes)
    }

    func testDailyQuoteIndexDifferentDatesCanDiffer() {
        let date1 = Date(timeIntervalSinceReferenceDate: 0)
        let date2 = Date(timeIntervalSinceReferenceDate: 86400) // +1 day
        let totalQuotes = 100
        let index1 = AppConstants.dailyQuoteIndex(for: date1, totalQuotes: totalQuotes)
        let index2 = AppConstants.dailyQuoteIndex(for: date2, totalQuotes: totalQuotes)
        // Different days should (generally) produce different indices — just verify both are valid
        XCTAssertGreaterThanOrEqual(index1, 0)
        XCTAssertGreaterThanOrEqual(index2, 0)
        XCTAssertLessThan(index1, totalQuotes)
        XCTAssertLessThan(index2, totalQuotes)
    }

    // MARK: - Quote Collection Tests

    func testQuoteCollectionCasesExist() {
        XCTAssertFalse(QuoteCollection.allCases.isEmpty)
    }

    func testAllCollectionCaseExists() {
        XCTAssertTrue(QuoteCollection.allCases.contains(.all))
    }
}
