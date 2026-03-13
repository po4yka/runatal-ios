//
//  RunicQuotesUISmokeTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

@testable import RunicQuotes
@preconcurrency import XCTest

final class RunicQuotesUISmokeTests: RunicQuotesUITestCase {
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
        let quoteText = app.staticTexts["quoteText"]
        XCTAssertTrue(quoteText.waitForExistence(timeout: 8), "Migrated quote text should be visible")
        XCTAssertTrue(
            quoteText.label.contains(UITestPersistentStoreConfigurator.legacyQuoteText),
            "Migrated legacy quote should be visible after launch",
        )
    }
}
