//
//  TipKitUITests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

@preconcurrency import XCTest

final class TipKitUITests: RunicQuotesUITestCase {
    override var launchesAppInSetUp: Bool {
        false
    }

    func testHomeNextQuoteTipAppearsOnFirstRun() {
        let app = self.launchLiveTipApp()

        let nextButton = self.button(in: app, identifier: "quote_next_button", labels: ["New Quote", "Next Quote"])
        XCTAssertTrue(nextButton.waitForExistence(timeout: 8), "Next quote button should exist")

        XCTAssertTrue(
            self.findStaticText(in: app, text: "Cycle the reading", maxSwipes: 2).waitForExistence(timeout: 8),
            "Next-quote tip should appear on first run",
        )
    }

    func testShowAllTranslationTipAppears() {
        let app = self.launchTipApp(showAllTips: true)
        XCTAssertTrue(
            self.findStaticText(in: app, text: "Use the right translation path", maxSwipes: 1).exists,
            "Translation tip should be visible",
        )
    }

    private func launchLiveTipApp(searchQuery: String? = nil) -> XCUIApplication {
        var environment = [
            "TIPKIT_RESET": "1",
            "TIPKIT_LIVE": "1",
            "TIPKIT_UI_INLINE_MIRRORS": "1",
        ]
        if let searchQuery {
            environment["UI_TEST_SEARCH_QUERY"] = searchQuery
        }
        return self.launchApp(extraEnvironment: environment)
    }

    private func launchTipApp(showAllTips: Bool) -> XCUIApplication {
        var environment = [
            "TIPKIT_RESET": "1",
            "UI_TEST_OPEN_TRANSLATION": "1",
        ]

        if showAllTips {
            environment["TIPKIT_SHOW_ALL"] = "1"
        }

        return self.launchApp(extraEnvironment: environment)
    }
}
