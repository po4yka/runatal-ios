//
//  RunicQuotesUITests.swift
//  RunicQuotesUITests
//
//  Created by Claude on 2025-11-15.
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
        app = nil
    }

    // MARK: - Launch Tests

    func testAppLaunches() {
        // Then: App should launch successfully
        let app = tryUnwrapApp()
        XCTAssertTrue(app.state == .runningForeground, "App should be running")
    }

    func testTabBarExists() {
        // Then: Tab bar should exist with both tabs
        let app = tryUnwrapApp()
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")

        let quoteTab = app.tabBars.buttons["Quote"]
        let settingsTab = app.tabBars.buttons["Settings"]

        XCTAssertTrue(quoteTab.exists, "Quote tab should exist")
        XCTAssertTrue(settingsTab.exists, "Settings tab should exist")
    }

    // MARK: - Quote View Tests

    func testQuoteViewDisplaysQuote() {
        let app = tryUnwrapApp()
        let quoteCard = app.otherElements["quote_card"]
        let quoteText = app.staticTexts["quoteText"]
        let authorText = app.staticTexts["authorText"]

        XCTAssertTrue(quoteCard.waitForExistence(timeout: 5), "Quote card should appear")
        XCTAssertTrue(quoteText.waitForExistence(timeout: 5), "Quote text should appear")
        XCTAssertTrue(authorText.waitForExistence(timeout: 5), "Author should appear")
    }

    func testScriptSelectorExists() {
        // Then: Script selector should exist
        let app = tryUnwrapApp()
        let selector = app.otherElements["quote_script_selector"]
        let elderButton = app.buttons["Elder Futhark"]
        let youngerButton = app.buttons["Younger Futhark"]
        let cirthButton = app.buttons["Cirth (Angerthas)"]

        XCTAssertTrue(selector.waitForExistence(timeout: 5), "Script selector should exist")
        XCTAssertTrue(elderButton.waitForExistence(timeout: 5), "Elder Futhark button should exist")
        XCTAssertTrue(youngerButton.exists, "Younger Futhark button should exist")
        XCTAssertTrue(cirthButton.exists, "Cirth button should exist")
    }

    func testSwitchingScripts() {
        // Given: App loaded
        let app = tryUnwrapApp()
        let youngerButton = app.buttons["Younger Futhark"]
        XCTAssertTrue(youngerButton.waitForExistence(timeout: 5), "Younger Futhark button should exist")

        // When: Tapping Younger Futhark
        youngerButton.tap()

        // Then: quote remains visible after script change
        let quoteCard = app.otherElements["quote_card"]
        XCTAssertTrue(quoteCard.waitForExistence(timeout: 5), "Quote card should remain visible")
        XCTAssertTrue(youngerButton.exists, "Younger Futhark button should still exist")
    }

    func testNextQuoteButton() {
        // Given: App loaded with quote
        let app = tryUnwrapApp()
        let nextButton = app.buttons["quote_next_button"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5), "Next button should exist")

        // When: Tapping next button
        nextButton.tap()

        // Then: Should still be interactive
        XCTAssertTrue(nextButton.exists, "Next button should still exist")
    }

    func testSaveButton() {
        // Given: App loaded
        let app = tryUnwrapApp()
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
        // When: Tapping settings tab
        let app = tryUnwrapApp()
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "Settings tab should exist")

        settingsTab.tap()

        // Then: Settings view should appear
        let header = app.otherElements["settings_header"]
        XCTAssertTrue(header.waitForExistence(timeout: 5), "Settings header should appear")
    }

    func testSettingsViewHasScriptSelection() {
        // Given: On settings screen
        let app = tryUnwrapApp()
        app.tabBars.buttons["Settings"].tap()

        // Then: Script selection should exist
        let scriptSection = app.otherElements["settings_script_section"]
        XCTAssertTrue(scriptSection.waitForExistence(timeout: 5), "Script section should exist")
    }

    func testSettingsViewHasFontSelection() {
        // Given: On settings screen
        let app = tryUnwrapApp()
        app.tabBars.buttons["Settings"].tap()

        // Then: Font selection should exist
        let fontSection = app.otherElements["settings_font_section"]
        XCTAssertTrue(fontSection.waitForExistence(timeout: 5), "Font section should exist")
    }

    func testSettingsViewHasWidgetMode() {
        // Given: On settings screen
        let app = tryUnwrapApp()
        app.tabBars.buttons["Settings"].tap()

        // Then: Widget settings should exist
        let widgetSection = app.otherElements["settings_widget_section"]
        XCTAssertTrue(widgetSection.waitForExistence(timeout: 5), "Widget section should exist")
    }

    func testSettingsViewHasAboutSection() {
        // Given: On settings screen
        let app = tryUnwrapApp()
        app.tabBars.buttons["Settings"].tap()

        // Then: About section should exist
        let aboutSection = app.otherElements["settings_about_section"]
        XCTAssertTrue(aboutSection.waitForExistence(timeout: 5), "About section should exist")
    }

    func testSettingsCanOpenTranslationScreen() {
        let app = tryUnwrapApp()
        openTranslationFromSettings(app)
        assertTranslationScreenVisible(in: app)
    }

    func testHomeCreateMenuCanOpenTranslationScreen() {
        let app = tryUnwrapApp()
        openTranslationFromCreateMenu(app)
        assertTranslationScreenVisible(in: app)
    }

    func testTranslationScreenSupportsModeSwitchAndAccuracyContext() {
        let app = tryUnwrapApp()
        openTranslationFromCreateMenu(app)
        assertTranslationScreenVisible(in: app)

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
        let app = tryUnwrapApp()
        openTranslationFromCreateMenu(app)
        assertTranslationScreenVisible(in: app)

        let input = app.textViews["translation_input_editor"]
        XCTAssertTrue(input.waitForExistence(timeout: 5), "Translation input should exist")
        input.tap()
        input.typeText("The wolf hunts at night")

        let translateButton = app.segmentedControls.buttons["Translate"]
        XCTAssertTrue(translateButton.waitForExistence(timeout: 5), "Translate mode should exist")
        translateButton.tap()

        XCTAssertTrue(app.staticTexts["Historical translation currently supports English input only."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Reconstructed"].exists)
        XCTAssertTrue(app.staticTexts["Supported"].exists)
    }

    func testTranslationScreenCanOpenSourcesSheet() {
        let app = tryUnwrapApp()
        openTranslationFromCreateMenu(app)
        assertTranslationScreenVisible(in: app)

        let input = app.textViews["translation_input_editor"]
        XCTAssertTrue(input.waitForExistence(timeout: 5), "Translation input should exist")
        input.tap()
        input.typeText("The wolf hunts at night")

        let translateButton = app.segmentedControls.buttons["Translate"]
        XCTAssertTrue(translateButton.waitForExistence(timeout: 5), "Translate mode should exist")
        translateButton.tap()

        let sourcesButton = app.buttons["Sources"]
        XCTAssertTrue(sourcesButton.waitForExistence(timeout: 5), "Sources button should exist")
        sourcesButton.tap()

        XCTAssertTrue(app.navigationBars["Sources"].waitForExistence(timeout: 5), "Sources sheet should appear")
    }

    // MARK: - Navigation Tests

    func testSwitchBetweenTabs() {
        // Given: On Quote tab
        let app = tryUnwrapApp()
        let quoteTab = app.tabBars.buttons["Quote"]
        let settingsTab = app.tabBars.buttons["Settings"]

        // When: Switching to Settings
        settingsTab.tap()

        // Then: Should be on Settings
        let settingsHeader = app.otherElements["settings_header"]
        XCTAssertTrue(settingsHeader.waitForExistence(timeout: 5), "Should show Settings")

        // When: Switching back to Quote
        quoteTab.tap()

        // Then: Should be back on Quote view
        let quoteText = app.staticTexts["quoteText"]
        XCTAssertTrue(quoteText.waitForExistence(timeout: 5), "Should show quote again")
    }

    // MARK: - Accessibility Tests

    func testAccessibilityLabels() {
        // Check that key elements have accessibility
        let app = tryUnwrapApp()
        let quoteTab = app.tabBars.buttons["Quote"]
        let settingsTab = app.tabBars.buttons["Settings"]

        XCTAssertEqual(quoteTab.label, "Quote", "Quote tab should expose its accessibility label")
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
        let app = tryUnwrapApp()
        measure {
            app.tabBars.buttons["Settings"].tap()
            app.tabBars.buttons["Quote"].tap()
        }
    }

    private func tryUnwrapApp(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIApplication {
        guard let app else {
            XCTFail("XCUIApplication was not initialized", file: file, line: line)
            return XCUIApplication()
        }

        return app
    }

    private func openTranslationFromSettings(_ app: XCUIApplication) {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "Settings tab should exist")
        settingsTab.tap()

        let translationLink = translationLink(in: app)
        XCTAssertTrue(translationLink.waitForExistence(timeout: 5), "Translation link should exist")
        translationLink.tap()
    }

    private func openTranslationFromCreateMenu(_ app: XCUIApplication) {
        let createMenu = app.buttons["quote_create_menu"]
        XCTAssertTrue(createMenu.waitForExistence(timeout: 5), "Create menu should exist")
        createMenu.tap()

        let translateButton = app.buttons["Translate"]
        XCTAssertTrue(translateButton.waitForExistence(timeout: 5), "Translate menu action should exist")
        translateButton.tap()
    }

    private func assertTranslationScreenVisible(in app: XCUIApplication) {
        let accuracyButton = app.buttons["translation_accuracy_button"]
        XCTAssertTrue(accuracyButton.waitForExistence(timeout: 5), "Accuracy button should exist")
    }

    private func translationLink(in app: XCUIApplication) -> XCUIElement {
        let identifier = app.descendants(matching: .any)["settings_translation_link"]
        let button = app.buttons["Translation"]
        let text = app.staticTexts["Translation"]

        for _ in 0..<5 {
            if identifier.exists { return identifier }
            if button.exists { return button }
            if text.exists { return text }
            app.swipeUp()
        }

        return identifier
    }
}
