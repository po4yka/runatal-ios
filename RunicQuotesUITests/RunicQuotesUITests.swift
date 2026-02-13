//
//  RunicQuotesUITests.swift
//  RunicQuotesUITests
//
//  Created by Claude on 2025-11-15.
//

import XCTest

final class RunicQuotesUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Launch Tests

    func testAppLaunches() {
        // Then: App should launch successfully
        XCTAssertTrue(app.state == .runningForeground, "App should be running")
    }

    func testTabBarExists() {
        // Then: Tab bar should exist with both tabs
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")

        let quoteTab = app.tabBars.buttons["Quote"]
        let settingsTab = app.tabBars.buttons["Settings"]

        XCTAssertTrue(quoteTab.exists, "Quote tab should exist")
        XCTAssertTrue(settingsTab.exists, "Settings tab should exist")
    }

    // MARK: - Quote View Tests

    func testQuoteViewDisplaysQuote() {
        let quoteCard = app.otherElements["quote_card"]
        let quoteText = app.staticTexts["quoteText"]
        let authorText = app.staticTexts["authorText"]

        XCTAssertTrue(quoteCard.waitForExistence(timeout: 5), "Quote card should appear")
        XCTAssertTrue(quoteText.waitForExistence(timeout: 5), "Quote text should appear")
        XCTAssertTrue(authorText.waitForExistence(timeout: 5), "Author should appear")
    }

    func testScriptSelectorExists() {
        // Then: Script selector should exist
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
        let nextButton = app.buttons["quote_next_button"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5), "Next button should exist")

        // When: Tapping next button
        nextButton.tap()

        // Then: Should still be interactive
        XCTAssertTrue(nextButton.exists, "Next button should still exist")
    }

    func testShuffleButton() {
        // Given: App loaded
        let shuffleButton = app.buttons["quote_shuffle_button"]

        if shuffleButton.waitForExistence(timeout: 5) {
            // When: Tapping shuffle
            shuffleButton.tap()

            // Then: Should trigger action
            XCTAssertTrue(shuffleButton.exists, "Shuffle button should still exist")
        }
    }

    // MARK: - Settings View Tests

    func testNavigateToSettings() {
        // When: Tapping settings tab
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "Settings tab should exist")

        settingsTab.tap()

        // Then: Settings view should appear
        let header = app.otherElements["settings_header"]
        XCTAssertTrue(header.waitForExistence(timeout: 5), "Settings header should appear")
    }

    func testSettingsViewHasScriptSelection() {
        // Given: On settings screen
        app.tabBars.buttons["Settings"].tap()

        // Then: Script selection should exist
        let scriptSection = app.otherElements["settings_script_section"]
        XCTAssertTrue(scriptSection.waitForExistence(timeout: 5), "Script section should exist")
    }

    func testSettingsViewHasFontSelection() {
        // Given: On settings screen
        app.tabBars.buttons["Settings"].tap()

        // Then: Font selection should exist
        let fontSection = app.otherElements["settings_font_section"]
        XCTAssertTrue(fontSection.waitForExistence(timeout: 5), "Font section should exist")
    }

    func testSettingsViewHasWidgetMode() {
        // Given: On settings screen
        app.tabBars.buttons["Settings"].tap()

        // Then: Widget settings should exist
        let widgetSection = app.otherElements["settings_widget_section"]
        XCTAssertTrue(widgetSection.waitForExistence(timeout: 5), "Widget section should exist")
    }

    func testSettingsViewHasAboutSection() {
        // Given: On settings screen
        app.tabBars.buttons["Settings"].tap()

        // Then: About section should exist
        let aboutSection = app.otherElements["settings_about_section"]
        XCTAssertTrue(aboutSection.waitForExistence(timeout: 5), "About section should exist")
    }

    // MARK: - Navigation Tests

    func testSwitchBetweenTabs() {
        // Given: On Quote tab
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
        let quoteTab = app.tabBars.buttons["Quote"]
        let settingsTab = app.tabBars.buttons["Settings"]

        XCTAssertTrue(quoteTab.isAccessibilityElement, "Quote tab should be accessible")
        XCTAssertTrue(settingsTab.isAccessibilityElement, "Settings tab should be accessible")
    }

    // MARK: - Performance Tests

    func testLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    func testTabSwitchingPerformance() {
        measure {
            app.tabBars.buttons["Settings"].tap()
            app.tabBars.buttons["Quote"].tap()
        }
    }
}
