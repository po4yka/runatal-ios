//
//  RunicQuotesUITests.swift
//  RunicQuotes
//
//  Created by Claude on 30.10.25.
//

@preconcurrency import XCTest

final class RunicQuotesUITests: XCTestCase {
    private var app: XCUIApplication?

    override func setUpWithError() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["UI_TESTING"] = "1"
        app.launchEnvironment["SKIP_ONBOARDING"] = "1"
        self.app = app
        app.launch()
    }

    override func tearDownWithError() throws {
        self.app = nil
    }

    // MARK: - Launch Tests

    func testAppLaunches() {
        // Then: App should launch successfully
        let app = self.tryUnwrapApp()
        XCTAssertTrue(app.state == .runningForeground, "App should be running")
    }

    func testTabBarExists() {
        let app = self.tryUnwrapApp()
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")

        let homeTab = self.tabButton(in: app, identifier: "home_tab", labels: ["Home"])
        let settingsTab = self.tabButton(in: app, identifier: "settings_tab", labels: ["Settings"])

        XCTAssertTrue(homeTab.exists, "Home tab should exist")
        XCTAssertTrue(settingsTab.exists, "Settings tab should exist")
    }

    // MARK: - Quote View Tests

    func testQuoteViewDisplaysQuote() {
        let app = self.tryUnwrapApp()
        let quoteCard = app.otherElements["quote_card"]
        let quoteText = app.staticTexts["quoteText"]
        let authorText = app.staticTexts["authorText"]

        XCTAssertTrue(quoteCard.waitForExistence(timeout: 5), "Quote card should appear")
        XCTAssertTrue(quoteText.waitForExistence(timeout: 5), "Quote text should appear")
        XCTAssertTrue(authorText.waitForExistence(timeout: 5), "Author should appear")
    }

    func testScriptSelectorExists() {
        let app = self.tryUnwrapApp()
        let selector = self.findElement(in: app, identifier: "quote_script_selector", maxSwipes: 1)

        XCTAssertTrue(selector.waitForExistence(timeout: 5), "Script selector should exist")
        XCTAssertEqual(selector.label, "Runic script selector", "Selector should expose an accessibility label")
        XCTAssertNotNil(selector.value as? String, "Selector should expose the current script value")
    }

    func testSwitchingScripts() {
        let app = self.tryUnwrapApp()
        let youngerButton = self.scriptSelectorButton(
            in: app,
            identifier: "quote_script_selector",
            labelContains: "Younger Futhark",
        )
        XCTAssertTrue(youngerButton.waitForExistence(timeout: 5), "Younger Futhark button should exist")

        self.tapElement(youngerButton)

        let quoteCard = app.otherElements["quote_card"]
        XCTAssertTrue(quoteCard.waitForExistence(timeout: 5), "Quote card should remain visible")
    }

    func testNextQuoteButton() {
        // Given: App loaded with quote
        let app = self.tryUnwrapApp()
        let nextButton = app.buttons["quote_next_button"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5), "Next button should exist")

        // When: Tapping next button
        nextButton.tap()

        // Then: Should still be interactive
        XCTAssertTrue(nextButton.exists, "Next button should still exist")
    }

    func testSaveButton() {
        // Given: App loaded
        let app = self.tryUnwrapApp()
        let saveButton = app.buttons["quote_save_button"]

        if saveButton.waitForExistence(timeout: 5) {
            // When: Tapping save
            saveButton.tap()

            // Then: Should trigger action
            XCTAssertTrue(saveButton.exists, "Save button should still exist")
        }
    }

    // MARK: - Settings View Tests

    func testNavigateToSettings() {
        let app = self.tryUnwrapApp()
        self.openSettings(in: app)

        let header = self.findElement(in: app, identifier: "settings_header", maxSwipes: 2)
        XCTAssertTrue(header.waitForExistence(timeout: 5), "Settings header should appear")
    }

    func testSettingsViewHasScriptSelection() {
        let app = self.tryUnwrapApp()
        self.openSettings(in: app)

        let scriptSection = self.findElement(in: app, identifier: "settings_script_section", maxSwipes: 3)
        XCTAssertTrue(scriptSection.waitForExistence(timeout: 5), "Script section should exist")
    }

    func testSettingsViewHasFontSelection() {
        let app = self.tryUnwrapApp()
        self.openSettings(in: app)

        let fontSection = self.findElement(in: app, identifier: "settings_font_section", maxSwipes: 4)
        XCTAssertTrue(fontSection.waitForExistence(timeout: 5), "Font section should exist")
    }

    func testSettingsViewHasWidgetMode() {
        let app = self.tryUnwrapApp()
        self.openSettings(in: app)

        let widgetSection = self.findElement(in: app, identifier: "settings_widget_section", maxSwipes: 5)
        XCTAssertTrue(widgetSection.waitForExistence(timeout: 5), "Widget section should exist")
    }

    func testSettingsViewHasAboutSection() {
        let app = self.tryUnwrapApp()
        self.openSettings(in: app)

        let aboutSection = self.findElement(in: app, identifier: "settings_about_section", maxSwipes: 6)
        XCTAssertTrue(aboutSection.waitForExistence(timeout: 5), "About section should exist")
    }

    func testSettingsCanOpenTranslationScreen() {
        let app = self.tryUnwrapApp()
        self.openTranslationFromSettings(app)
        self.assertTranslationScreenVisible(in: app)
    }

    func testHomeCreateMenuCanOpenTranslationScreen() {
        let app = self.tryUnwrapApp()
        self.openTranslationFromCreateMenu(app)
        self.assertTranslationScreenVisible(in: app)
    }

    func testTranslationScreenSupportsModeSwitchAndAccuracyContext() {
        let app = self.tryUnwrapApp()
        self.openTranslationFromCreateMenu(app)
        self.assertTranslationScreenVisible(in: app)

        let input = app.textViews["translation_input_editor"]
        XCTAssertTrue(input.waitForExistence(timeout: 5), "Translation input should exist")

        input.tap()
        input.typeText("Honor the old ways")

        let translateButton = app.segmentedControls.buttons["Translate"]
        XCTAssertTrue(translateButton.waitForExistence(timeout: 5), "Translate mode should exist")
        translateButton.tap()

        let accuracyButton = app.buttons["translation_accuracy_button"]
        XCTAssertTrue(accuracyButton.waitForExistence(timeout: 5), "Accuracy button should exist")
        accuracyButton.tap()

        let accuracyTitle = app.navigationBars["Accuracy & Context"]
        XCTAssertTrue(accuracyTitle.waitForExistence(timeout: 5), "Accuracy screen should appear")
        XCTAssertTrue(app.staticTexts["How to read the results"].exists, "Accuracy guidance should exist")
    }

    func testTranslationScreenShowsEnglishOnlyBannerAndEvidenceBadges() {
        let app = self.tryUnwrapApp()
        self.openTranslationFromCreateMenu(app)
        self.assertTranslationScreenVisible(in: app)
        self.selectYoungerTranslationScript(in: app)

        let input = app.textViews["translation_input_editor"]
        XCTAssertTrue(input.waitForExistence(timeout: 5), "Translation input should exist")
        input.tap()
        input.typeText("The wolf hunts at night")

        let translateButton = app.segmentedControls.buttons["Translate"]
        XCTAssertTrue(translateButton.waitForExistence(timeout: 5), "Translate mode should exist")
        self.tapElement(translateButton)

        XCTAssertTrue(
            self.findElement(in: app, identifier: "translation_source_language_banner", maxSwipes: 3).waitForExistence(timeout: 5),
            "English-only support banner should exist",
        )
        XCTAssertTrue(
            self.findElement(in: app, identifier: "translation_evidence_badge", maxSwipes: 3).waitForExistence(timeout: 5),
            "Evidence badge should exist",
        )
        XCTAssertTrue(
            self.findElement(in: app, identifier: "translation_support_badge", maxSwipes: 3).waitForExistence(timeout: 5),
            "Support badge should exist",
        )
    }

    func testTranslationScreenCanOpenSourcesSheet() {
        let app = self.tryUnwrapApp()
        self.openTranslationFromCreateMenu(app)
        self.assertTranslationScreenVisible(in: app)
        self.selectYoungerTranslationScript(in: app)

        let input = app.textViews["translation_input_editor"]
        XCTAssertTrue(input.waitForExistence(timeout: 5), "Translation input should exist")
        input.tap()
        input.typeText("The wolf hunts at night")

        let translateButton = app.segmentedControls.buttons["Translate"]
        XCTAssertTrue(translateButton.waitForExistence(timeout: 5), "Translate mode should exist")
        self.tapElement(translateButton)

        let sourcesButton = self.findElement(in: app, identifier: "translation_sources_button", maxSwipes: 4)
        XCTAssertTrue(sourcesButton.waitForExistence(timeout: 5), "Sources button should exist")
        self.tapElement(sourcesButton)

        XCTAssertTrue(app.navigationBars["Sources"].waitForExistence(timeout: 5), "Sources sheet should appear")
    }

    // MARK: - Navigation Tests

    func testSwitchBetweenTabs() {
        let app = self.tryUnwrapApp()
        let homeTab = self.tabButton(in: app, identifier: "home_tab", labels: ["Home"])
        let settingsTab = self.tabButton(in: app, identifier: "settings_tab", labels: ["Settings"])

        self.tapElement(settingsTab)

        let settingsHeader = self.findElement(in: app, identifier: "settings_header", maxSwipes: 2)
        XCTAssertTrue(settingsHeader.waitForExistence(timeout: 5), "Should show Settings")

        self.tapElement(homeTab)

        let quoteText = app.staticTexts["quoteText"]
        XCTAssertTrue(quoteText.waitForExistence(timeout: 5), "Should show quote again")
    }

    // MARK: - Accessibility Tests

    func testAccessibilityLabels() {
        let app = self.tryUnwrapApp()
        let homeTab = self.tabButton(in: app, identifier: "home_tab", labels: ["Home"])
        let settingsTab = self.tabButton(in: app, identifier: "settings_tab", labels: ["Settings"])

        XCTAssertEqual(homeTab.label, "Home", "Home tab should expose its accessibility label")
        XCTAssertEqual(settingsTab.label, "Settings", "Settings tab should expose its accessibility label")
    }

    // MARK: - Performance Tests

    func testLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchEnvironment["UI_TESTING"] = "1"
            app.launchEnvironment["SKIP_ONBOARDING"] = "1"
            app.launch()
        }
    }

    func testTabSwitchingPerformance() {
        let app = self.tryUnwrapApp()
        let settingsTab = self.tabButton(in: app, identifier: "settings_tab", labels: ["Settings"])
        let homeTab = self.tabButton(in: app, identifier: "home_tab", labels: ["Home"])

        measure {
            self.tapElement(settingsTab)
            self.tapElement(homeTab)
        }
    }

    private func tryUnwrapApp(
        file: StaticString = #filePath,
        line: UInt = #line,
    ) -> XCUIApplication {
        guard let app else {
            XCTFail("XCUIApplication was not initialized", file: file, line: line)
            return XCUIApplication()
        }

        return app
    }

    private func openTranslationFromSettings(_ app: XCUIApplication) {
        self.openSettings(in: app)
        let translationLink = translationLink(in: app)
        XCTAssertTrue(translationLink.waitForExistence(timeout: 5), "Translation link should exist")
        self.tapElement(translationLink)
    }

    private func openTranslationFromCreateMenu(_ app: XCUIApplication) {
        let createMenu = app.buttons["quote_create_menu"]
        XCTAssertTrue(createMenu.waitForExistence(timeout: 5), "Create menu should exist")
        self.tapElement(createMenu)

        let translateButton = app.buttons["Translate"]
        XCTAssertTrue(translateButton.waitForExistence(timeout: 5), "Translate menu action should exist")
        self.tapElement(translateButton)
    }

    private func assertTranslationScreenVisible(in app: XCUIApplication) {
        let accuracyButton = self.findElement(in: app, identifier: "translation_accuracy_button", maxSwipes: 1)
        XCTAssertTrue(accuracyButton.waitForExistence(timeout: 5), "Accuracy button should exist")
    }

    private func selectYoungerTranslationScript(in app: XCUIApplication) {
        let youngerButton = self.scriptSelectorButton(
            in: app,
            identifier: "translation_script_selector",
            labelContains: "Younger Futhark",
        )
        XCTAssertTrue(youngerButton.waitForExistence(timeout: 5), "Translation script selector should exist")
        self.tapElement(youngerButton)
    }

    private func openSettings(in app: XCUIApplication) {
        let settingsTab = self.tabButton(in: app, identifier: "settings_tab", labels: ["Settings"])
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "Settings tab should exist")
        self.tapElement(settingsTab)
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

    private func button(containingLabel label: String, in app: XCUIApplication) -> XCUIElement {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", label)
        return app.buttons.matching(predicate).firstMatch
    }

    private func scriptSelectorButton(
        in app: XCUIApplication,
        identifier: String,
        labelContains labelFragment: String,
    ) -> XCUIElement {
        let predicate = NSPredicate(
            format: "identifier == %@ AND label CONTAINS[c] %@",
            identifier,
            labelFragment,
        )
        return app.buttons.matching(predicate).firstMatch
    }

    private func findElement(
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

    private func tapElement(_ element: XCUIElement) {
        if element.isHittable {
            element.tap()
            return
        }

        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    private func translationLink(in app: XCUIApplication) -> XCUIElement {
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
