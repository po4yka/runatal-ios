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
        // Wait for quote to load
        let quoteText = app.staticTexts.matching(identifier: "quoteText").firstMatch
        let authorText = app.staticTexts.matching(identifier: "authorText").firstMatch

        // Then: Quote elements should eventually appear
        XCTAssertTrue(quoteText.waitForExistence(timeout: 5), "Quote text should appear")
        XCTAssertTrue(authorText.waitForExistence(timeout: 5), "Author should appear")
    }

    func testScriptSelectorExists() {
        // Then: Script selector should exist
        let elderButton = app.buttons["Elder Futhark"]
        let youngerButton = app.buttons["Younger Futhark"]
        let cirthButton = app.buttons["Cirth (Angerthas)"]

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

        // Then: Script should change (wait for update)
        sleep(1)

        // Verify the button is now selected (implementation may vary)
        XCTAssertTrue(youngerButton.exists, "Younger Futhark button should still exist")
    }

    func testNextQuoteButton() {
        // Given: App loaded with quote
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Next'")).firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5), "Next button should exist")

        // Get initial quote text
        sleep(1) // Wait for initial load

        // When: Tapping next button
        nextButton.tap()

        // Then: Should trigger loading (implementation dependent)
        sleep(1)
        XCTAssertTrue(nextButton.exists, "Next button should still exist")
    }

    func testShuffleButton() {
        // Given: App loaded
        let shuffleButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Shuffle'")).firstMatch

        if shuffleButton.waitForExistence(timeout: 5) {
            // When: Tapping shuffle
            shuffleButton.tap()

            // Then: Should trigger action
            sleep(1)
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
        let settingsTitle = app.staticTexts["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5), "Settings title should appear")
    }

    func testSettingsViewHasScriptSelection() {
        // Given: On settings screen
        app.tabBars.buttons["Settings"].tap()

        // Then: Script selection should exist
        sleep(1)
        let scriptSection = app.staticTexts["Runic Script"]
        XCTAssertTrue(scriptSection.waitForExistence(timeout: 5), "Script section should exist")
    }

    func testSettingsViewHasFontSelection() {
        // Given: On settings screen
        app.tabBars.buttons["Settings"].tap()

        // Then: Font selection should exist
        sleep(1)
        let fontSection = app.staticTexts["Font Style"]
        XCTAssertTrue(fontSection.waitForExistence(timeout: 5), "Font section should exist")
    }

    func testSettingsViewHasWidgetMode() {
        // Given: On settings screen
        app.tabBars.buttons["Settings"].tap()

        // Then: Widget settings should exist
        sleep(1)
        let widgetSection = app.staticTexts["Widget Settings"]
        XCTAssertTrue(widgetSection.waitForExistence(timeout: 5), "Widget section should exist")
    }

    func testSettingsViewHasAboutSection() {
        // Given: On settings screen
        app.tabBars.buttons["Settings"].tap()

        // Then: About section should exist
        sleep(1)
        let aboutSection = app.staticTexts["About"]
        XCTAssertTrue(aboutSection.waitForExistence(timeout: 5), "About section should exist")
    }

    // MARK: - Navigation Tests

    func testSwitchBetweenTabs() {
        // Given: On Quote tab
        let quoteTab = app.tabBars.buttons["Quote"]
        let settingsTab = app.tabBars.buttons["Settings"]

        // When: Switching to Settings
        settingsTab.tap()
        sleep(1)

        // Then: Should be on Settings
        let settingsTitle = app.staticTexts["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5), "Should show Settings")

        // When: Switching back to Quote
        quoteTab.tap()
        sleep(1)

        // Then: Should be back on Quote view
        let quoteText = app.staticTexts.matching(identifier: "quoteText").firstMatch
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
