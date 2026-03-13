//
//  RunicQuotesUISmokeTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

@preconcurrency import XCTest

@MainActor
final class RunicQuotesUISmokeTests: RunicQuotesUITestCase {
    private let legacyQuoteText = "Legacy store quote survives migration."

    override var launchesAppInSetUp: Bool {
        false
    }

    func testCleanLaunchShowsMainQuoteWithoutFallbackBanner() {
        let app = self.launchApp(extraEnvironment: [
            "UI_TEST_RESET_PERSISTENT_STORE": "1",
        ])

        self.waitForQuoteCard(in: app, timeout: 8)
        self.assertNoFallbackBanner(in: app)
    }

    func testLegacyStoreMigratesAndShowsLegacyQuote() {
        let app = self.launchApp(extraEnvironment: [
            "UI_TEST_RESET_PERSISTENT_STORE": "1",
            "UI_TEST_INSTALL_LEGACY_STORE": "1",
        ])

        self.waitForQuoteCard(in: app, timeout: 8)
        self.assertNoFallbackBanner(in: app)

        let searchTab = self.tabButton(in: app, identifier: "search_tab", labels: ["Search"])
        XCTAssertTrue(searchTab.waitForExistence(timeout: 5), "Search tab should exist")
        self.tapElement(searchTab)

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Search field should exist")
        searchField.tap()
        searchField.typeText(self.legacyQuoteText)

        let migratedQuote = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] %@", self.legacyQuoteText),
        ).firstMatch
        XCTAssertTrue(
            migratedQuote.waitForExistence(timeout: 8),
            "Migrated legacy quote should be discoverable after launch",
        )
    }
}
