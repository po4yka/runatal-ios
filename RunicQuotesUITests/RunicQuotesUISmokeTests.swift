//
//  RunicQuotesUISmokeTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import XCTest

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

        let savedTab = self.tabButton(in: app, identifier: "saved_tab", labels: ["Saved"])
        XCTAssertTrue(savedTab.waitForExistence(timeout: 5))
        self.tapElement(savedTab)
        let legacyIdentity = app.buttons["open_quote_7B5D7832-E0A4-4E76-91F1-D06F3559E3A5"]
        XCTAssertTrue(legacyIdentity.waitForExistence(timeout: 8), "The original bookmarked UUID must survive migration")
        self.tapElement(legacyIdentity)
        self.waitForQuoteCard(in: app)
        let quote = app.staticTexts["quoteText"]
        let restored = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", self.legacyQuoteText), object: quote)
        XCTAssertEqual(XCTWaiter.wait(for: [restored], timeout: 8), .completed)
        self.selectHomeScript(in: app, script: "ELDER_FUTHARK")
        let runic = app.descendants(matching: .any)["runic_text"]
        XCTAssertEqual(runic.value as? String, "ᛚᛖᚷᚨᚲᛁ", "Exact user-owned legacy rune text must survive")
        self.assertNoFallbackBanner(in: app)
    }
}
