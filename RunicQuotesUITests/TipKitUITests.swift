//
//  TipKitUITests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

@preconcurrency import XCTest

final class TipKitUITests: XCTestCase {
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
        let app = XCUIApplication()
        app.launchEnvironment["UI_TESTING"] = "1"
        app.launchEnvironment["SKIP_ONBOARDING"] = "1"
        app.launchEnvironment["TIPKIT_RESET"] = "1"
        app.launchEnvironment["TIPKIT_LIVE"] = "1"
        app.launchEnvironment["TIPKIT_UI_INLINE_MIRRORS"] = "1"
        if let searchQuery {
            app.launchEnvironment["UI_TEST_SEARCH_QUERY"] = searchQuery
        }
        app.launch()
        return app
    }

    private func launchTipApp(showAllTips: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UI_TESTING"] = "1"
        app.launchEnvironment["SKIP_ONBOARDING"] = "1"
        app.launchEnvironment["TIPKIT_RESET"] = "1"
        app.launchEnvironment["UI_TEST_OPEN_TRANSLATION"] = "1"

        if showAllTips {
            app.launchEnvironment["TIPKIT_SHOW_ALL"] = "1"
        }

        app.launch()
        return app
    }

    private func openSettings(in app: XCUIApplication) {
        self.tapElement(self.tabButton(in: app, identifier: "settings_tab", labels: ["Settings"]))
    }

    private func tabButton(in app: XCUIApplication, identifier: String, labels: [String]) -> XCUIElement {
        let identifiedButton = app.tabBars.buttons[identifier]
        if identifiedButton.waitForExistence(timeout: 1) {
            return identifiedButton
        }

        for label in labels {
            let labeledButton = app.tabBars.buttons[label]
            if labeledButton.waitForExistence(timeout: 1) {
                return labeledButton
            }
        }

        return identifiedButton
    }

    private func button(in app: XCUIApplication, identifier: String, labels: [String]) -> XCUIElement {
        let identifiedButton = app.buttons[identifier]
        if identifiedButton.waitForExistence(timeout: 1) {
            return identifiedButton
        }

        for label in labels {
            let labeledButton = app.buttons[label]
            if labeledButton.waitForExistence(timeout: 1) {
                return labeledButton
            }
        }

        return identifiedButton
    }

    private func findElement(
        in app: XCUIApplication,
        identifier: String,
        maxSwipes: Int,
    ) -> XCUIElement {
        let element = app.descendants(matching: .any)[identifier]

        for _ in 0 ... maxSwipes {
            if element.exists {
                return element
            }
            app.swipeUp()
        }

        for _ in 0 ... maxSwipes {
            if element.exists {
                return element
            }
            app.swipeDown()
        }

        return element
    }

    private func findStaticText(
        in app: XCUIApplication,
        text: String,
        maxSwipes: Int,
    ) -> XCUIElement {
        let label = app.staticTexts[text]

        for _ in 0 ... maxSwipes {
            if label.exists {
                return label
            }
            app.swipeUp()
        }

        for _ in 0 ... maxSwipes {
            if label.exists {
                return label
            }
            app.swipeDown()
        }

        return label
    }

    private func tapElement(_ element: XCUIElement) {
        if element.isHittable {
            element.tap()
            return
        }

        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    private func waitForNonExistence(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if !element.exists {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }

        return !element.exists
    }
}
