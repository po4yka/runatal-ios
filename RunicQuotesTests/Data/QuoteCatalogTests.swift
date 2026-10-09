//
//  QuoteCatalogTests.swift
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
struct QuoteCatalogTests {
    @Test
    func seededIdentityMatchesAcrossStoresAndEraseDoesNotResurrectLibrary() throws {
        let firstContext = try TestSupport.makeModelContext()
        let first = SwiftDataQuoteRepository(modelContext: firstContext)
        let second = try SwiftDataQuoteRepository(modelContext: TestSupport.makeModelContext())
        try first.seedIfNeeded()
        try second.seedIfNeeded()
        let original = try first.allQuotes()
        #expect(try Set(original.map(\.id)) == Set(second.allQuotes().map(\.id)))
        for quote in original {
            try first.eraseQuote(id: quote.id)
        }
        try first.seedIfNeeded()
        #expect(try first.allQuotes().isEmpty)
        #expect(try ModelContext(firstContext.container).fetchCount(FetchDescriptor<QuoteSeedReceipt>()) == original.count)
    }

    @Test
    func catalogAdditionPreservesEditedAndErasedMembers() throws {
        let context = try TestSupport.makeModelContext()
        let entry = QuoteCatalogEntry(id: "audit-one", textLatin: "Original", author: "Audit", collection: .stoic)
        let first = SwiftDataQuoteRepository(modelContext: context, catalogLoader: { [entry] })
        try first.seedIfNeeded()
        let record = try #require(first.allQuotes().first)
        _ = try first.updateQuote(id: record.id, textLatin: "User edit", author: "User", source: nil, collection: .motivation)
        let addition = QuoteCatalogEntry(id: "audit-two", textLatin: "Addition", author: "Audit", collection: .stoic)
        let updated = SwiftDataQuoteRepository(modelContext: context, catalogLoader: { [entry, addition] })
        try updated.seedIfNeeded()
        #expect(try updated.allQuotes().count == 2)
        #expect(try updated.quote(id: record.id)?.textLatin == "User edit")
        try updated.eraseQuote(id: record.id)
        try updated.seedIfNeeded()
        #expect(try updated.allQuotes().map(\.textLatin) == ["Addition"])
    }

    @Test
    func legacyAdoptionPreservesUUIDBookmarksUserEditsAndDeletedBaseline() throws {
        let context = try TestSupport.makeModelContext()
        let legacyEntry = try #require(QuoteSeedCatalog.legacyIdentities().first)
        let quote = Quote(textLatin: legacyEntry.textLatin, author: legacyEntry.author)
        let originalID = quote.id
        context.insert(quote)
        let edited = Quote(textLatin: "Edited before upgrade", author: "User")
        context.insert(edited)
        let preferences = UserPreferences(savedQuoteIDs: [originalID, edited.id])
        preferences.id = UUID()
        preferences.singletonKey = nil
        preferences.catalogIdentityVersion = nil
        context.insert(preferences)
        try context.save()
        let repository = SwiftDataQuoteRepository(modelContext: context)
        try repository.seedIfNeeded()
        #expect(try repository.allQuotes().count == 6)
        let currentEntry = try #require(QuoteSeedCatalog.load().first { $0.id == legacyEntry.id })
        #expect(try repository.quote(id: originalID)?.textLatin == currentEntry.textLatin)
        #expect(try repository.quote(id: originalID)?.source == currentEntry.source)
        #expect(try repository.quote(id: edited.id)?.textLatin == "Edited before upgrade")
        let persisted = ModelContext(context.container)
        #expect(try persisted.fetch(FetchDescriptor<Quote>()).first { $0.id == originalID }?.builtInID == legacyEntry.id)
        #expect(try SwiftDataUserPreferencesRepository(modelContext: context).snapshot().savedQuoteIDs == [originalID, edited.id])
        #expect(try persisted.fetchCount(FetchDescriptor<QuoteSeedReceipt>()) == 44)
    }

    @Test
    func initializedEmptyLegacyStoreDoesNotRestoreErasedBuiltIns() throws {
        let context = try TestSupport.makeModelContext()
        let preferences = UserPreferences()
        preferences.catalogIdentityVersion = nil
        context.insert(preferences)
        try context.save()
        let repository = SwiftDataQuoteRepository(modelContext: context)
        try repository.seedIfNeeded()
        #expect(try repository.allQuotes().count == 4)
        #expect(try repository.allQuotes().allSatisfy { $0.source?.contains("RuneS") == true })
        #expect(try ModelContext(context.container).fetchCount(FetchDescriptor<QuoteSeedReceipt>()) == 44)
    }

    @Test
    func legacyPreferenceDuplicatesKeepNewestAppearanceAndUnionLibraryMembership() throws {
        let context = try TestSupport.makeModelContext()
        let firstID = UUID()
        let secondID = UUID()
        let first = UserPreferences(selectedTheme: .obsidian, savedQuoteIDs: [firstID])
        first.id = UUID()
        first.singletonKey = nil
        first.installedPackIDs = ["havamal"]
        first.lastUpdated = Date(timeIntervalSince1970: 1)
        let second = UserPreferences(selectedTheme: .nordicDawn, savedQuoteIDs: [secondID])
        second.id = UUID()
        second.singletonKey = nil
        second.lastUpdated = Date(timeIntervalSince1970: 2)
        context.insert(first)
        context.insert(second)
        try context.save()
        let snapshot = try SwiftDataUserPreferencesRepository(modelContext: context).snapshot()
        #expect(snapshot.selectedTheme == .nordicDawn)
        #expect(snapshot.savedQuoteIDs == [firstID, secondID])
        #expect(snapshot.installedPackIDs == ["havamal"])
        #expect(try ModelContext(context.container).fetchCount(FetchDescriptor<UserPreferences>()) == 1)
    }

    @Test
    func concurrentActorSeedsCannotCreateDuplicateBuiltInIdentities() async throws {
        let container = try TestSupport.makeModelContainer()
        let first = QuoteProvider(modelContainer: container)
        let second = QuoteProvider(modelContainer: container)
        async let firstSeed: Void = first.seedIfNeeded()
        async let secondSeed: Void = second.seedIfNeeded()
        _ = try await (firstSeed, secondSeed)
        let records = try await first.allQuotes()
        #expect(records.count == 44)
        #expect(Set(records.map(\.id)).count == 44)
    }

}
