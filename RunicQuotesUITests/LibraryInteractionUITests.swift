//
//  LibraryInteractionUITests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import XCTest

@MainActor
final class LibraryInteractionUITests: RunicQuotesUITestCase {
    override var defaultLaunchEnvironment: [String: String] {
        var environment = super.defaultLaunchEnvironment
        environment["UI_TEST_RESET_PERSISTENT_STORE"] = "1"
        return environment
    }

    func testBookmarkAndRemovalRefreshSavedAcrossTabReturns() {
        let app = self.requireApp()
        self.waitForQuoteCard(in: app)
        let text = app.staticTexts["quoteText"].value as? String
        XCTAssertNotNil(text)
        let save = app.buttons["quote_save_button"]
        self.tapElement(save)
        let saved = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS[c] %@", "Saved"), object: save)
        XCTAssertEqual(XCTWaiter.wait(for: [saved], timeout: 5), .completed)
        let savedTab = self.tabButton(in: app, identifier: "saved_tab", labels: ["Saved"])
        self.tapElement(savedTab)
        let open = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "open_quote_")).firstMatch
        XCTAssertTrue(open.waitForExistence(timeout: 5))
        let originalIdentity = open.identifier
        let savedPassage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", text ?? "")).firstMatch
        XCTAssertTrue(savedPassage.exists)
        self.tapElement(open)
        self.waitForQuoteCard(in: app)
        XCTAssertEqual(app.staticTexts["quoteText"].value as? String, text)
        self.tapElement(app.buttons["quote_save_button"])
        let unsaved = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Save"), object: app.buttons["quote_save_button"])
        XCTAssertEqual(XCTWaiter.wait(for: [unsaved], timeout: 5), .completed)
        self.tapElement(savedTab)
        let removed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: app.buttons[originalIdentity])
        XCTAssertEqual(XCTWaiter.wait(for: [removed], timeout: 5), .completed)
    }

    func testDailyReminderSchedulesAndRetainsEnabledStateAcrossRelaunch() {
        let app = self.requireApp()
        self.openSettings(in: app)
        let toggle = self.findElement(in: app, identifier: "daily_reminder_enabled", maxSwipes: 7)
        XCTAssertTrue(toggle.exists)
        self.tapElement(toggle)
        // This interaction runs only on the CI job's dedicated Simulator.
        // The system may already have authorization from an earlier normal interaction.
        let allow = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Allow"]
        if allow.waitForExistence(timeout: 3) {
            self.tapElement(allow)
        }
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "1"), object: toggle)
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 5), .completed)
        let relaunched = self.launchApp(extraEnvironment: ["UI_TEST_RESET_PERSISTENT_STORE": "0"])
        self.openSettings(in: relaunched)
        let restored = self.findElement(in: relaunched, identifier: "daily_reminder_enabled", maxSwipes: 7)
        let persisted = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "1"), object: restored)
        XCTAssertEqual(XCTWaiter.wait(for: [persisted], timeout: 5), .completed)
        XCTAssertFalse(relaunched.staticTexts["daily_reminder_error"].exists)
        self.tapElement(restored)
        let disabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "0"), object: restored)
        XCTAssertEqual(XCTWaiter.wait(for: [disabled], timeout: 5), .completed)
    }

    func testInstalledPackAppearsInSearchAndOpensItsSourcedPassage() {
        let app = self.requireApp()
        self.tapElement(self.tabButton(in: app, identifier: "collections_tab", labels: ["Collections"]))
        let packs = self.findElement(in: app, identifier: "quote_packs_link", maxSwipes: 5)
        XCTAssertTrue(packs.exists)
        self.tapElement(packs)
        let havamal = self.findElement(in: app, identifier: "pack_havamal", maxSwipes: 4)
        XCTAssertTrue(havamal.exists)
        self.tapElement(havamal)
        let install = self.findElement(in: app, identifier: "install_pack_havamal", maxSwipes: 5)
        XCTAssertTrue(install.exists)
        self.tapElement(install)
        let installed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: install)
        XCTAssertEqual(XCTWaiter.wait(for: [installed], timeout: 5), .completed)
        self.tapElement(self.tabButton(in: app, identifier: "search_tab", labels: ["Search"]))
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        self.tapElement(search)
        search.typeText("Within the gates ere a man shall go")
        let passage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Within the gates ere a man shall go")).firstMatch
        XCTAssertTrue(passage.waitForExistence(timeout: 5))
        let open = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "open_quote_")).firstMatch
        XCTAssertTrue(open.exists)
        self.tapElement(open)
        self.waitForQuoteCard(in: app)
        XCTAssertTrue((app.staticTexts["quoteText"].value as? String ?? "").contains("Within the gates ere a man shall go"))
        let source = self.findElement(in: app, identifier: "quote_source_button", maxSwipes: 5)
        XCTAssertTrue(source.exists)
        self.tapElement(source)
        XCTAssertTrue(app.descendants(matching: .any)["quote_source_sheet"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Hávamál, stanza 1")).firstMatch.exists)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Installed-pack-original-passage-provenance"
        attachment.lifetime = .keepAlways
        self.add(attachment)
    }

    func testCirthReferenceShowsTheNumberedCatalogWithItsNativeFont() {
        let app = self.requireApp()
        self.openSettings(in: app)
        let reference = self.findStaticText(in: app, text: "Rune Reference", maxSwipes: 5)
        XCTAssertTrue(reference.exists)
        self.tapElement(reference)
        XCTAssertTrue(app.navigationBars["Rune Reference"].waitForExistence(timeout: 5))
        let cirth = self.findElement(in: app, identifier: "script_option_CIRTH", maxSwipes: 3)
        self.tapElement(cirth)
        let selected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "Selected"), object: cirth)
        XCTAssertEqual(XCTWaiter.wait(for: [selected], timeout: 5), .completed)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Certh 1")).firstMatch.exists)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Actual-Cirth-numbered-reference-catalog"
        attachment.lifetime = .keepAlways
        self.add(attachment)
    }

    func testCirthShareUsesActualFontAndDisclosesCopyRequirements() {
        let app = self.requireApp()
        self.waitForQuoteCard(in: app)
        let cirth = self.findElement(in: app, identifier: "script_option_CIRTH", maxSwipes: 3)
        self.tapElement(cirth)
        let selected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "Selected"), object: cirth)
        XCTAssertEqual(XCTWaiter.wait(for: [selected], timeout: 5), .completed)
        let actions = self.findElement(in: app, identifier: "quote_actions_button", maxSwipes: 4)
        self.tapElement(actions)
        let share = app.buttons["Share Quote"]
        XCTAssertTrue(share.waitForExistence(timeout: 5))
        self.tapElement(share)
        XCTAssertTrue(app.navigationBars["Share"].waitForExistence(timeout: 5))
        let guidance = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Copied text needs a compatible font")).firstMatch
        XCTAssertTrue(guidance.exists)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Actual-Cirth-share-private-use-guidance"
        attachment.lifetime = .keepAlways
        self.add(attachment)
    }
}
