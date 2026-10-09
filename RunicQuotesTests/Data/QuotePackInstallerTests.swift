//
//  QuotePackInstallerTests.swift
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
struct QuotePackInstallerTests {
    @Test
    func catalogCountsAndPreviewsMatchSourceLocatedContent() throws {
        let packs = try QuotePack.loadCatalog()
        #expect(packs.map(\.quoteCount) == [32, 48, 24, 36, 20])
        #expect(packs.reduce(0) { $0 + $1.quoteCount } == 160)
        for pack in packs {
            #expect(pack.previewQuotes == Array(pack.quotes.prefix(4).map(\.textLatin)))
            #expect(pack.quotes.allSatisfy { $0.source?.contains("https://") == true })
        }
        let meditations = try #require(packs.first { $0.id == "meditations" })
        #expect(meditations.quotes.allSatisfy { $0.collection == .stoic })
    }

    @Test
    func installImportsRealSearchableQuotesAndPreservesUnrelatedPreferences() throws {
        let context = try TestSupport.makeModelContext()
        let preferences = UserPreferences(selectedTheme: .nordicDawn, savedQuoteIDs: [UUID()])
        let saved = preferences.savedQuoteIDs
        context.insert(preferences)
        try context.save()
        let installer = QuotePackInstaller(modelContext: context)
        #expect(try installer.install(packID: "havamal") == 32)
        let records = try SwiftDataQuoteRepository(modelContext: context).allQuotes()
        #expect(records.count == 32)
        #expect(records.contains { $0.textLatin.contains("Within the gates") })
        #expect(records.allSatisfy { !$0.isUserGenerated && $0.source != nil && $0.runicElder?.isEmpty == false })
        let snapshot = try SwiftDataUserPreferencesRepository(modelContext: context).snapshot()
        #expect(snapshot.savedQuoteIDs == saved)
        #expect(snapshot.selectedTheme == .nordicDawn)
        #expect(snapshot.installedPackIDs == ["havamal"])
    }

    @Test
    func repeatedInstallKeepsIdentitiesAndDoesNotResurrectErasedQuotes() throws {
        let context = try TestSupport.makeModelContext()
        let installer = QuotePackInstaller(modelContext: context)
        let repository = SwiftDataQuoteRepository(modelContext: context)
        try installer.install(packID: "prose-edda")
        let original = try repository.allQuotes()
        #expect(try installer.install(packID: "prose-edda") == 0)
        #expect(try Set(repository.allQuotes().map(\.id)) == Set(original.map(\.id)))
        let erased = try #require(original.first)
        try repository.eraseQuote(id: erased.id)
        #expect(try installer.install(packID: "prose-edda") == 0)
        #expect(try repository.quote(id: erased.id) == nil)
        #expect(try repository.allQuotes().count == 19)
    }

    @Test
    func failedCommitRollsBackQuotesReceiptsAndInstalledFlag() throws {
        let context = try TestSupport.makeModelContext()
        let failing = QuotePackInstaller(modelContext: context, commit: { _ in throw TestError(message: "save failed") })
        #expect(throws: TestError.self) { try failing.install(packID: "stoic-letters") }
        let persisted = ModelContext(context.container)
        #expect(try persisted.fetchCount(FetchDescriptor<Quote>()) == 0)
        #expect(try persisted.fetchCount(FetchDescriptor<QuoteSeedReceipt>()) == 0)
        #expect(try persisted.fetchCount(FetchDescriptor<UserPreferences>()) == 0)
    }

    @Test
    func legacyInstalledFlagGainsContentOnBootstrapWithoutDuplicates() throws {
        let context = try TestSupport.makeModelContext()
        let preferences = UserPreferences()
        preferences.installedPackIDs = ["meditations"]
        context.insert(preferences)
        try context.save()
        let repository = SwiftDataQuoteRepository(modelContext: context)
        try repository.seedIfNeeded()
        #expect(try repository.allQuotes().count == 52)
        try repository.seedIfNeeded()
        #expect(try repository.allQuotes().count == 52)
        #expect(try repository.allQuotes().filter { $0.collection == .stoic }.count == 48)
    }

    @Test
    func unknownPackFailsWithoutPersistingAnything() throws {
        let context = try TestSupport.makeModelContext()
        #expect(throws: QuoteRepositoryError.self) { try QuotePackInstaller(modelContext: context).install(packID: "unknown") }
        #expect(try ModelContext(context.container).fetchCount(FetchDescriptor<Quote>()) == 0)
    }
}
