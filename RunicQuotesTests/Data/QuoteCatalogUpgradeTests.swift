//
//  QuoteCatalogUpgradeTests.swift
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
struct QuoteCatalogUpgradeTests {
    @Test
    func pristineLegacyQuoteGainsCorrectSourceAndKeepsIdentityBookmarksAndArchiveState() throws {
        let context = try TestSupport.makeModelContext()
        let original = try #require(QuoteSeedCatalog.legacyIdentities().first)
        let replacement = try #require(QuoteSeedCatalog.load().first { $0.id == original.id })
        let quote = self.makeLegacyQuote(original)
        quote.isHidden = true
        quote.isSoftDeleted = true
        quote.deletedAt = Date(timeIntervalSince1970: 123)
        context.insert(quote)
        context.insert(QuoteSeedReceipt(seedID: original.id, quoteID: quote.id))
        let preferences = UserPreferences(savedQuoteIDs: [quote.id])
        preferences.catalogIdentityVersion = "v1"
        context.insert(preferences)
        try context.save()
        let translations = SwiftDataTranslationRepository(modelContext: context)
        let service = HistoricalTranslationService()
        try translations.cache(result: service.translate(text: original.textLatin, script: .cirth), for: quote.id, sourceText: original.textLatin)
        let repository = SwiftDataQuoteRepository(modelContext: context)
        try repository.seedIfNeeded()
        let persisted = try #require(try repository.quote(id: quote.id))
        #expect(persisted.textLatin == replacement.textLatin)
        #expect(persisted.author == replacement.author)
        #expect(persisted.source == replacement.source)
        #expect(persisted.isHidden && persisted.isDeleted)
        #expect(persisted.deletedAt == quote.deletedAt)
        #expect(try SwiftDataUserPreferencesRepository(modelContext: context).snapshot().savedQuoteIDs == [quote.id])
        #expect(persisted.runicElder == RunicTransliterator.transliterate(replacement.textLatin, to: .elder).glyphOutput)
        #expect(try ModelContext(context.container).fetchCount(FetchDescriptor<TranslationRecord>()) == 0)
    }

    @Test
    func userEditsCustomGlyphsAndStoredHistoricalArtifactsAreNeverRewritten() throws {
        let context = try TestSupport.makeModelContext()
        let originals = try QuoteSeedCatalog.legacyIdentities()
        let edited = self.makeLegacyQuote(originals[0])
        edited.textLatin = "User’s own wording"
        let custom = self.makeLegacyQuote(originals[4])
        custom.runicElder = "CUSTOM GLYPHS"
        let historical = self.makeLegacyQuote(originals[2])
        historical.storedTranslationMetadataData = Data("saved historical artifact".utf8)
        let sourceEdited = self.makeLegacyQuote(originals[3])
        sourceEdited.source = "User’s own source"
        for quote in [edited, custom, historical, sourceEdited] {
            context.insert(quote)
            try context.insert(QuoteSeedReceipt(seedID: #require(quote.builtInID), quoteID: quote.id))
        }
        try context.save()
        let repository = SwiftDataQuoteRepository(modelContext: context)
        try repository.seedIfNeeded()
        #expect(try repository.quote(id: edited.id)?.textLatin == "User’s own wording")
        #expect(try repository.quote(id: custom.id)?.runicElder == "CUSTOM GLYPHS")
        #expect(try repository.quote(id: custom.id)?.textLatin == originals[4].textLatin)
        #expect(try repository.quote(id: custom.id)?.source?.contains("original attribution is not revalidated") == true)
        #expect(try repository.quote(id: historical.id)?.textLatin == originals[2].textLatin)
        #expect(try repository.quote(id: historical.id)?.storedTranslationMetadataData == historical.storedTranslationMetadataData)
        #expect(try repository.quote(id: sourceEdited.id)?.source == "User’s own source")
    }

    @Test
    func revisedCatalogIsCompleteAndEveryEntryHasHonestSource() throws {
        let entries = try QuoteSeedCatalog.load()
        #expect(entries.count == 44)
        #expect(entries.allSatisfy { $0.source?.contains("https://") == true })
        let film = try #require(entries.first { $0.id == "builtin-0003" })
        #expect(film.source?.contains("film") == true)
        #expect(film.source?.contains("In copyright") == true)
        #expect(entries.first { $0.id == "builtin-0001" }?.source?.contains("stanza 78") == true)
    }

    private func makeLegacyQuote(_ entry: QuoteCatalogEntry) -> Quote {
        let quote = Quote(textLatin: entry.textLatin, author: entry.author, collection: entry.collection)
        quote.builtInID = entry.id
        quote.runicElder = RunicTransliterator.transliterate(entry.textLatin, to: .elder).glyphOutput
        quote.runicYounger = RunicTransliterator.transliterate(entry.textLatin, to: .younger).glyphOutput
        quote.runicCirth = RunicTransliterator.transliterate(entry.textLatin, to: .cirth).glyphOutput
        return quote
    }
}
