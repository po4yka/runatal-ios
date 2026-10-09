//
//  PersistentStoreMigrationTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
@testable import RunicQuotes
import SwiftData
import Testing

@MainActor
@Suite(.serialized, .tags(.repository))
struct PersistentStoreMigrationTests {
    @Test
    func actualLegacyStoreUpgradePreservesQuotesBookmarksAndDuplicatePreferenceData() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "runatal-migration-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appending(path: "default.store")
        try UITestPersistentStoreConfigurator.installLegacyStore(at: storeURL, withLegacyPreferences: true)
        let schema = Schema([Quote.self, QuoteSeedReceipt.self, UserPreferences.self, TranslationRecord.self, TranslationBackfillState.self])
        let config = ModelConfiguration(schema: schema, url: storeURL)
        let container = try ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)
        let before = try #require(context.fetch(FetchDescriptor<Quote>()).first { !$0.isSoftDeleted })
        #expect(before.id.uuidString == "7B5D7832-E0A4-4E76-91F1-D06F3559E3A5")
        #expect(before.textLatin == UITestPersistentStoreConfigurator.legacyQuoteText)
        #expect(!before.isHidden && !before.isSoftDeleted)
        #expect(before.runicElder == "ᛚᛖᚷᚨᚲᛁ")
        #expect(before.runicYounger == "ᛚᛁᚴᚨᛋᛁ")
        #expect(before.runicCirth == "legacy")
        let preferences = SwiftDataUserPreferencesRepository(modelContext: context)
        let snapshot = try preferences.snapshot()
        #expect(snapshot.selectedTheme == .nordicDawn)
        #expect(snapshot.selectedScript == .younger)
        #expect(snapshot.selectedFont == .babelstone)
        #expect(snapshot.savedQuoteIDs == [before.id, UITestPersistentStoreConfigurator.legacyArchivedQuoteID])
        #expect(snapshot.installedPackIDs == ["havamal", "meditations"])
        let quotes = SwiftDataQuoteRepository(modelContext: context)
        try quotes.seedIfNeeded()
        let after = try #require(try quotes.quote(id: before.id))
        #expect(after.textLatin == before.textLatin)
        #expect(after.runicCirth == "\u{E09E}\u{E0AF}\u{E092}\u{E0B1}\u{E091}\u{E0A8}")
        #expect(!after.isHidden && !after.isDeleted)
        #expect(try quotes.allQuotes().count == 85)
        #expect(try quotes.allQuotes().filter { $0.source?.contains("Project Gutenberg") == true }.count == 80)
        #expect(try preferences.snapshot().savedQuoteIDs == [before.id, UITestPersistentStoreConfigurator.legacyArchivedQuoteID])
        let archived = try #require(quotes.archivedQuotes().first)
        #expect(archived.id == UITestPersistentStoreConfigurator.legacyArchivedQuoteID)
        #expect(archived.isDeleted && !archived.isHidden)
        #expect(archived.deletedAt == Date(timeIntervalSince1970: 1_700_000_000))
        #expect(archived.runicCirth == "\u{E09E}\u{E0AF}\u{E092}\u{E0B1}\u{E091}\u{E0A8}-\u{E087}\u{E08B}\u{E0B1}\u{E0B9}\u{E0A1}")
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<UserPreferences>()) == 1)
    }
}
