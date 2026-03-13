//
//  UserPreferencesRepositoryTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation
@testable import RunicQuotes
import SwiftData
import Testing

@Suite(.serialized, .tags(.repository))
struct UserPreferencesRepositoryTests {
    @Test
    func snapshotRoundTripsSavedState() throws {
        let context = try TestSupport.makeModelContext()
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

        #expect(restored.selectedScript == .cirth)
        #expect(restored.selectedFont == .cirth)
        #expect(restored.widgetMode == .random)
        #expect(restored.selectedCollection == .stoic)
        #expect(restored.widgetStyle == .translationFirst)
        #expect(!restored.widgetDecorativeGlyphsEnabled)
        #expect(restored.selectedTheme == .nordicDawn)
        #expect(restored.lastUsedPreset == .cirthLore)
        #expect(restored.savedQuoteIDs == snapshot.savedQuoteIDs)
        #expect(restored.installedPackIDs == snapshot.installedPackIDs)
    }
}
