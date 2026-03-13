//
//  UserPreferencesRepositoryTests.swift
//  RunicQuotesTests
//
//  Created by Codex on 2026-03-13.
//

import SwiftData
import XCTest
@testable import RunicQuotes

final class UserPreferencesRepositoryTests: XCTestCase {
    func testSnapshotRoundTripsSavedState() throws {
        let schema = Schema([Quote.self, UserPreferences.self, TranslationRecord.self, TranslationBackfillState.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)
        let repository = SwiftDataUserPreferencesRepository(modelContext: context)

        var snapshot = UserPreferencesSnapshot()
        snapshot.selectedScript = .cirth
        snapshot.selectedFont = .cirth
        snapshot.widgetMode = .random
        snapshot.selectedCollection = .stoic
        snapshot.widgetStyle = .translationFirst
        snapshot.widgetDecorativeGlyphsEnabled = false
        snapshot.selectedTheme = .nordicDawn
        snapshot.lastUsedPreset = .cirthLore
        snapshot.savedQuoteIDs = [UUID(), UUID()]
        snapshot.installedPackIDs = ["stoic-pack", "tolkien-pack"]

        try repository.save(snapshot)

        let restored = try repository.snapshot()
        XCTAssertEqual(restored.selectedScript, .cirth)
        XCTAssertEqual(restored.selectedFont, .cirth)
        XCTAssertEqual(restored.widgetMode, .random)
        XCTAssertEqual(restored.selectedCollection, .stoic)
        XCTAssertEqual(restored.widgetStyle, .translationFirst)
        XCTAssertFalse(restored.widgetDecorativeGlyphsEnabled)
        XCTAssertEqual(restored.selectedTheme, .nordicDawn)
        XCTAssertEqual(restored.lastUsedPreset, .cirthLore)
        XCTAssertEqual(restored.savedQuoteIDs, snapshot.savedQuoteIDs)
        XCTAssertEqual(restored.installedPackIDs, snapshot.installedPackIDs)
    }
}
