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

        let preferences = UserPreferences()
        preferences.installedPackIDs = snapshot.installedPackIDs
        context.insert(preferences)
        try context.save()
        try repository.apply([
            .script(snapshot.selectedScript), .font(snapshot.selectedFont), .widgetMode(snapshot.widgetMode),
            .collection(snapshot.selectedCollection), .widgetStyle(snapshot.widgetStyle),
            .decorativeGlyphs(snapshot.widgetDecorativeGlyphsEnabled), .theme(snapshot.selectedTheme),
            .preset(.cirthLore),
        ] + snapshot.savedQuoteIDs.map(UserPreferencesMutation.toggleSavedQuote))
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

    @Test
    func independentActionsPreserveBookmarksPacksAndOtherSettings() throws {
        let context = try TestSupport.makeModelContext()
        let repository = SwiftDataUserPreferencesRepository(modelContext: context)
        let quoteID = UUID()
        _ = try repository.snapshot()
        try QuotePackInstaller(modelContext: context).install(packID: "havamal")
        try repository.apply([.toggleSavedQuote(quoteID), .collection(.stoic)])
        let result = try repository.apply([.theme(.nordicDawn)])
        #expect(result.savedQuoteIDs == [quoteID])
        #expect(result.installedPackIDs == ["havamal"])
        #expect(result.selectedCollection == .stoic)
        #expect(result.selectedTheme == .nordicDawn)
        try repository.apply([.removeSavedQuote(quoteID)])
        try repository.apply([.removeSavedQuote(quoteID)])
        #expect(try repository.snapshot().savedQuoteIDs.isEmpty)
    }

    @Test
    func invalidMutationDoesNotSaveEarlierChangesOrUnrelatedPendingWork() throws {
        let context = try TestSupport.makeModelContext()
        let repository = SwiftDataUserPreferencesRepository(modelContext: context)
        try repository.apply([.theme(.obsidian)])
        context.insert(Quote(textLatin: "Pending user work", author: "Audit"))
        #expect(throws: UserPreferencesMutationError.self) {
            try repository.apply([.theme(.nordicDawn), .font(.cirth)])
        }
        #expect(try repository.snapshot().selectedTheme == .obsidian)
        let independent = ModelContext(context.container)
        #expect(try independent.fetchCount(FetchDescriptor<Quote>()) == 0)
        #expect(context.hasChanges)
    }

}
