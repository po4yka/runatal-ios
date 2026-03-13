//
//  RunicQuotesUITestCase.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

@preconcurrency import XCTest

class RunicQuotesUITestCase: XCTestCase {
    private(set) var app: XCUIApplication?

    var launchesAppInSetUp: Bool {
        true
    }

    var defaultLaunchEnvironment: [String: String] {
        [
            "UI_TESTING": "1",
            "SKIP_ONBOARDING": "1",
        ]
    }

    override func setUpWithError() throws {
        continueAfterFailure = false

        if self.launchesAppInSetUp {
            _ = self.launchApp()
        }
    }

    override func tearDownWithError() throws {
        if let app, app.state != .notRunning {
            app.terminate()
        }
        self.app = nil
    }

    @discardableResult
    func launchApp(extraEnvironment: [String: String] = [:]) -> XCUIApplication {
        if let app, app.state != .notRunning {
            app.terminate()
        }

        let app = XCUIApplication()
        var environment = self.defaultLaunchEnvironment
        for (key, value) in extraEnvironment {
            environment[key] = value
        }
        app.launchEnvironment = environment
        app.launch()
        self.app = app
        return app
    }

    func makeApplication(extraEnvironment: [String: String] = [:]) -> XCUIApplication {
        let app = XCUIApplication()
        var environment = self.defaultLaunchEnvironment
        for (key, value) in extraEnvironment {
            environment[key] = value
        }
        app.launchEnvironment = environment
        return app
    }

    func requireApp(
        file: StaticString = #filePath,
        line: UInt = #line,
    ) -> XCUIApplication {
        guard let app else {
            XCTFail("XCUIApplication was not initialized", file: file, line: line)
            return XCUIApplication()
        }

        return app
    }

    func waitForQuoteCard(in app: XCUIApplication, timeout: TimeInterval = 5) {
        XCTAssertTrue(app.otherElements["quote_card"].waitForExistence(timeout: timeout), "Quote card should appear")
        XCTAssertTrue(app.staticTexts["quoteText"].waitForExistence(timeout: timeout), "Quote text should appear")
        XCTAssertTrue(app.staticTexts["authorText"].waitForExistence(timeout: timeout), "Author should appear")
    }

    func assertNoFallbackBanner(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line,
    ) {
        XCTAssertFalse(
            app.otherElements["database_error_banner"].exists,
            "App should be using the persistent store instead of the in-memory fallback",
            file: file,
            line: line,
        )
    }

    func openTranslationFromSettings(_ app: XCUIApplication) {
        self.openSettings(in: app)
        let link = self.translationLink(in: app)
        XCTAssertTrue(link.waitForExistence(timeout: 5), "Translation link should exist")
        self.tapElement(link)
    }

    func openTranslationFromCreateMenu(_ app: XCUIApplication) {
        let createMenu = app.buttons["quote_create_menu"]
        XCTAssertTrue(createMenu.waitForExistence(timeout: 5), "Create menu should exist")
        self.tapElement(createMenu)

        let translateButton = app.buttons["Translate"]
        XCTAssertTrue(translateButton.waitForExistence(timeout: 5), "Translate menu action should exist")
        self.tapElement(translateButton)
    }

    func assertTranslationScreenVisible(in app: XCUIApplication) {
        let accuracyButton = self.findElement(in: app, identifier: "translation_accuracy_button", maxSwipes: 1)
        XCTAssertTrue(accuracyButton.waitForExistence(timeout: 5), "Accuracy button should exist")
    }

    func selectYoungerTranslationScript(in app: XCUIApplication) {
        let youngerButton = self.scriptSelectorOption(in: app, identifier: "translation_script_selector", index: 1)
        XCTAssertTrue(youngerButton.waitForExistence(timeout: 5), "Translation script selector should exist")
        self.tapElement(youngerButton)
    }

    func openSettings(in app: XCUIApplication) {
        let settingsTab = self.tabButton(in: app, identifier: "settings_tab", labels: ["Settings"])
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "Settings tab should exist")
        self.tapElement(settingsTab)
    }

    func tabButton(in app: XCUIApplication, identifier: String, labels: [String]) -> XCUIElement {
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

    func button(in app: XCUIApplication, identifier: String, labels: [String]) -> XCUIElement {
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

    func button(containingLabel label: String, in app: XCUIApplication) -> XCUIElement {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", label)
        return app.buttons.matching(predicate).firstMatch
    }

    func scriptSelectorOption(
        in app: XCUIApplication,
        identifier: String,
        index: Int,
    ) -> XCUIElement {
        app.buttons.matching(identifier: identifier).element(boundBy: index)
    }

    func findElement(
        in app: XCUIApplication,
        identifier: String,
        maxSwipes: Int,
    ) -> XCUIElement {
        let element = app.descendants(matching: .any).matching(identifier: identifier).firstMatch

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

    func findStaticText(
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

    func tapElement(_ element: XCUIElement) {
        if element.isHittable {
            element.tap()
            return
        }

        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    func translationLink(in app: XCUIApplication) -> XCUIElement {
        let identifier = app.descendants(matching: .any)["settings_translation_link"]
        let button = app.buttons["Translation"]
        let text = app.staticTexts["Translation"]

        for _ in 0 ..< 5 {
            if identifier.exists { return identifier }
            if button.exists { return button }
            if text.exists { return text }
            app.swipeUp()
        }

        return identifier
    }
}
