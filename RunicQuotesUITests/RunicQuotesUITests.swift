//
//  RunicQuotesUITests.swift
//  RunicQuotes
//
//  Created by Claude on 30.10.25.
//

import XCTest

@MainActor
final class RunicQuotesUITests: RunicQuotesUITestCase {

    override var defaultLaunchEnvironment: [String: String] {
        var environment = super.defaultLaunchEnvironment
        environment["UI_TEST_RESET_PERSISTENT_STORE"] = "1"
        return environment
    }

    // MARK: - Launch Tests

    func testAppLaunches() {
        // Then: App should launch successfully
        let app = self.requireApp()
        XCTAssertTrue(app.state == .runningForeground, "App should be running")
    }

    func testTabBarExists() {
        let app = self.requireApp()
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")

        let homeTab = self.tabButton(in: app, identifier: "home_tab", labels: ["Home"])
        let settingsTab = self.tabButton(in: app, identifier: "settings_tab", labels: ["Settings"])

        XCTAssertTrue(homeTab.exists, "Home tab should exist")
        XCTAssertTrue(settingsTab.exists, "Settings tab should exist")
    }

    // MARK: - Quote View Tests

    func testQuoteViewDisplaysQuote() {
        let app = self.requireApp()
        self.waitForQuoteCard(in: app)
    }

    func testScriptSelectorExists() {
        let app = self.requireApp()
        for script in ["ELDER_FUTHARK", "YOUNGER_FUTHARK", "CIRTH"] {
            XCTAssertTrue(app.buttons["script_option_\(script)"].waitForExistence(timeout: 5))
        }
        XCTAssertEqual(app.buttons["script_option_ELDER_FUTHARK"].value as? String, "Selected")
    }

    func testSwitchingScripts() {
        let app = self.requireApp()
        for script in ["YOUNGER_FUTHARK", "CIRTH", "ELDER_FUTHARK"] {
            let option = self.findElement(in: app, identifier: "script_option_\(script)", maxSwipes: 3)
            XCTAssertTrue(option.exists)
            self.tapElement(option)
            let selected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "Selected"), object: option)
            XCTAssertEqual(XCTWaiter.wait(for: [selected], timeout: 5), .completed)
            self.waitForQuoteCard(in: app)
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "Home-\(script)-actual-registered-font"
            attachment.lifetime = .keepAlways
            self.add(attachment)
        }
    }

    func testNextQuoteButton() {
        // Given: App loaded with quote
        let app = self.requireApp()
        let nextButton = app.buttons["quote_next_button"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5), "Next button should exist")

        // When: Tapping next button
        nextButton.tap()

        // Then: Should still be interactive
        XCTAssertTrue(nextButton.exists, "Next button should still exist")
    }

    func testSaveButton() {
        // Given: App loaded
        let app = self.requireApp()
        let saveButton = app.buttons["quote_save_button"]

        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()
        let saved = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS[c] %@", "Saved"), object: saveButton)
        XCTAssertEqual(XCTWaiter.wait(for: [saved], timeout: 5), .completed)
    }

    // MARK: - Settings View Tests

    func testNavigateToSettings() {
        let app = self.requireApp()
        self.openSettings(in: app)

        let header = self.findElement(in: app, identifier: "settings_header", maxSwipes: 2)
        XCTAssertTrue(header.waitForExistence(timeout: 5), "Settings header should appear")
    }

    func testSettingsViewHasScriptSelection() {
        let app = self.requireApp()
        self.openSettings(in: app)

        let scriptSection = self.findElement(in: app, identifier: "settings_script_section", maxSwipes: 3)
        XCTAssertTrue(scriptSection.waitForExistence(timeout: 5), "Script section should exist")
    }

    func testSettingsViewHasFontSelection() {
        let app = self.requireApp()
        self.openSettings(in: app)

        let fontSection = self.findElement(in: app, identifier: "settings_font_section", maxSwipes: 4)
        XCTAssertTrue(fontSection.waitForExistence(timeout: 5), "Font section should exist")
    }

    func testSettingsViewHasWidgetMode() {
        let app = self.requireApp()
        self.openSettings(in: app)

        let widgetSection = self.findElement(in: app, identifier: "settings_widget_section", maxSwipes: 5)
        XCTAssertTrue(widgetSection.waitForExistence(timeout: 5), "Widget section should exist")
    }

    func testSettingsViewHasAboutSection() {
        let app = self.requireApp()
        self.openSettings(in: app)

        let aboutSection = self.findElement(in: app, identifier: "settings_about_section", maxSwipes: 6)
        XCTAssertTrue(aboutSection.waitForExistence(timeout: 5), "About section should exist")
    }

    func testSettingsCanOpenTranslationScreen() {
        let app = self.requireApp()
        self.openTranslationFromSettings(app)
        self.assertTranslationScreenVisible(in: app)
    }

    func testHomeCreateMenuCanOpenTheNewQuoteEditor() {
        let app = self.requireApp()
        let create = app.buttons["quote_create_menu"]
        XCTAssertTrue(create.waitForExistence(timeout: 5))
        self.tapElement(create)
        let newQuote = app.buttons["quote_create_new_action"]
        XCTAssertTrue(newQuote.waitForExistence(timeout: 5))
        self.tapElement(newQuote)
        XCTAssertTrue(app.navigationBars["New Quote"].waitForExistence(timeout: 5))
    }

    func testHomeCreateMenuCanOpenTranslationScreen() {
        let app = self.requireApp()
        self.openTranslationFromCreateMenu(app)
        self.assertTranslationScreenVisible(in: app)
    }

    func testTranslationScreenSupportsModeSwitchAndAccuracyContext() {
        let app = self.requireApp()
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
        let app = self.requireApp()
        self.enterRealYoungerTranslation(in: app)
        let banner = self.findElement(in: app, identifier: "translation_source_language_banner", maxSwipes: 4)
        XCTAssertTrue(banner.exists)
        XCTAssertTrue(banner.label.contains("English"))
        let badge = self.findElement(in: app, identifier: "translation_evidence_badge", maxSwipes: 4)
        XCTAssertTrue(badge.exists)
        XCTAssertEqual(badge.label, "Reconstructed")
        let output = self.findElement(in: app, identifier: "translation_output_text", maxSwipes: 5)
        XCTAssertTrue(output.exists)
        XCTAssertEqual(output.label, "ᚢᛚᚠᚱ ᚢᛅᛁᚦᛁᚱ ᚢᛘ ᚾᚢᛏᛏ")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Real-Younger-translation-with-evidence"
        attachment.lifetime = .keepAlways
        self.add(attachment)
    }

    func testTranslationScreenCanOpenSourcesSheet() {
        let app = self.requireApp()
        self.enterRealYoungerTranslation(in: app)
        let source = self.findElement(in: app, identifier: "translation_primary_source_label", maxSwipes: 4)
        XCTAssertTrue(source.exists)
        XCTAssertFalse(source.label.isEmpty)
        let sourceLabel = source.label
        let sources = self.findElement(in: app, identifier: "translation_sources_button", maxSwipes: 4)
        XCTAssertTrue(sources.exists)
        self.tapElement(sources)
        XCTAssertTrue(app.navigationBars["Sources"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[sourceLabel].waitForExistence(timeout: 5))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Actual-translation-provenance-sheet"
        attachment.lifetime = .keepAlways
        self.add(attachment)
    }

    private func enterRealYoungerTranslation(in app: XCUIApplication) {
        self.openTranslationFromCreateMenu(app)
        self.selectYoungerTranslationScript(in: app)
        let mode = app.segmentedControls.buttons["Translate"]
        XCTAssertTrue(mode.waitForExistence(timeout: 5))
        self.tapElement(mode)
        let input = self.findElement(in: app, identifier: "translation_input_editor", maxSwipes: 3)
        XCTAssertTrue(input.exists)
        self.tapElement(input)
        input.typeText("The wolf hunts at night")
        app.swipeUp()
    }

    // MARK: - Navigation Tests

    func testCollectionShelfSelectsTheMatchingHomeStream() {
        let app = self.requireApp()
        let collections = self.tabButton(in: app, identifier: "collections_tab", labels: ["Collections"])
        self.tapElement(collections)
        let shelf = self.findElement(in: app, identifier: "collection_Tolkien", maxSwipes: 4)
        XCTAssertTrue(shelf.exists)
        self.tapElement(shelf)
        self.waitForQuoteCard(in: app)
        let selection = app.buttons["collection_cover_Tolkien"]
        XCTAssertTrue(selection.exists)
        let selected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "Selected"), object: selection)
        XCTAssertEqual(XCTWaiter.wait(for: [selected], timeout: 5), .completed)
    }

    func testSwitchBetweenTabs() {
        let app = self.requireApp()
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
        let app = self.requireApp()
        let homeTab = self.tabButton(in: app, identifier: "home_tab", labels: ["Home"])
        let settingsTab = self.tabButton(in: app, identifier: "settings_tab", labels: ["Settings"])

        XCTAssertEqual(homeTab.label, "Home", "Home tab should expose its accessibility label")
        XCTAssertEqual(settingsTab.label, "Settings", "Settings tab should expose its accessibility label")
    }

    // MARK: - Performance Tests

    func testLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = self.makeApplication()
            app.launch()
        }
    }

    func testTabSwitchingPerformance() {
        let app = self.requireApp()
        let settingsTab = self.tabButton(in: app, identifier: "settings_tab", labels: ["Settings"])
        let homeTab = self.tabButton(in: app, identifier: "home_tab", labels: ["Home"])

        measure {
            self.tapElement(settingsTab)
            self.tapElement(homeTab)
        }
    }
}
