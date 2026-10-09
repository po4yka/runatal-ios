//
//  QuoteRepositoryTests.swift
//  RunicQuotes
//
//  Created by Claude on 30.10.25.
//

import Foundation
@testable import RunicQuotes
import SwiftData
import Testing

@Suite(.serialized, .tags(.repository))
struct QuoteRepositoryTests {
    @Test
    func seedIfNeededCreatesQuotes() throws {
        let (repository, context) = try makeRepository()

        #expect(try context.fetch(FetchDescriptor<Quote>()).isEmpty)

        try repository.seedIfNeeded()

        #expect(try !context.fetch(FetchDescriptor<Quote>()).isEmpty)
    }

    @Test
    func seedIfNeededIdempotent() throws {
        let (repository, context) = try makeRepository()

        try repository.seedIfNeeded()
        let firstCount = try context.fetch(FetchDescriptor<Quote>()).count

        try repository.seedIfNeeded()

        #expect(try context.fetch(FetchDescriptor<Quote>()).count == firstCount)
    }

    @Test
    func seededQuotesHaveTransliterations() throws {
        let (repository, context) = try makeRepository()
        try repository.seedIfNeeded()

        let quotes = try context.fetch(FetchDescriptor<Quote>())
        #expect(!quotes.isEmpty)

        for quote in quotes.prefix(5) {
            #expect(quote.runicElder != nil)
            #expect(quote.runicYounger != nil)
            #expect(quote.runicCirth != nil)
        }
    }

    @Test
    func seededQuotesHaveCollectionTags() throws {
        let (repository, context) = try makeRepository()
        try repository.seedIfNeeded()

        let quotes = try context.fetch(FetchDescriptor<Quote>())
        #expect(!quotes.isEmpty)

        for quote in quotes {
            #expect(quote.collectionRaw != nil)
            #expect(QuoteCollection(rawValue: quote.collectionRaw ?? "") != nil)
        }
    }

    @Test
    func quoteOfTheDayReturnsSameQuoteOnSameDay() throws {
        let (repository, _) = try makeRepository(seedData: true)

        let first = try repository.quoteOfTheDay(for: .elder)
        let second = try repository.quoteOfTheDay(for: .elder)

        #expect(first.id == second.id)
    }

    @Test
    func quoteOfTheDayWorksWithAllScripts() throws {
        let (repository, _) = try makeRepository(seedData: true)

        let elder = try repository.quoteOfTheDay(for: .elder)
        let younger = try repository.quoteOfTheDay(for: .younger)
        let cirth = try repository.quoteOfTheDay(for: .cirth)

        #expect(!elder.textLatin.isEmpty)
        #expect(!younger.textLatin.isEmpty)
        #expect(!cirth.textLatin.isEmpty)
    }

    @Test
    func quoteOfTheDayReturnsQuoteWithCorrectScript() throws {
        let (repository, _) = try makeRepository(seedData: true)
        let quote = try repository.quoteOfTheDay(for: .elder)
        #expect(quote.runicElder != nil)
    }

    @Test
    func randomQuoteReturnsQuote() throws {
        let (repository, _) = try makeRepository(seedData: true)
        let quote = try repository.randomQuote(for: .elder)
        #expect(!quote.textLatin.isEmpty)
        #expect(!quote.author.isEmpty)
    }

    @Test
    func randomQuoteCanReturnDifferentQuotes() throws {
        let (repository, _) = try makeRepository(seedData: true)

        var ids = Set<UUID>()
        for _ in 0 ..< 10 {
            try ids.insert(repository.randomQuote(for: .elder).id)
        }

        #expect(ids.count > 1)
    }

    @Test
    func allQuotesReturnsAllQuotes() throws {
        let (repository, _) = try makeRepository(seedData: true)
        let quotes = try repository.allQuotes()
        #expect(quotes.count == 40)
    }

    @Test
    func allQuotesReturnsSortedByCreatedAt() throws {
        let (repository, _) = try makeRepository(seedData: true)
        let quotes = try repository.allQuotes()

        for index in 0 ..< (quotes.count - 1) {
            #expect(quotes[index].createdAt <= quotes[index + 1].createdAt)
        }
    }

    @Test
    func createQuoteStoredRunicOverridesTransliteration() throws {
        let (repository, _) = try makeRepository()

        let record = try repository.createQuote(
            textLatin: "The wolf hunts at night",
            author: "Runatal",
            source: nil,
            collection: .motivation,
            storedRunic: RunicTextBundle(
                elder: "ELDER-OVERRIDE",
                younger: nil,
                cirth: "CIRTH-OVERRIDE",
            ),
        )

        #expect(record.runicElder == "ELDER-OVERRIDE")
        #expect(record.runicYounger == nil)
        #expect(record.runicCirth == "CIRTH-OVERRIDE")
    }

    @Test
    func updateQuoteDeletesCachedTranslationsWhenTextChanges() throws {
        let (repository, context) = try makeRepository()
        let translationRepository = SwiftDataTranslationRepository(modelContext: context)

        let record = try repository.createQuote(
            textLatin: "The wolf hunts at night",
            author: "Runatal",
            source: nil,
            collection: .motivation,
            storedRunic: nil,
        )
        try translationRepository.cache(
            result: TestSupport.makeTranslationResult(script: .elder, glyphOutput: "ᚹᚢᛚᚠᚨᛉ"),
            for: record.id,
            sourceText: record.textLatin,
        )

        #expect(try translationRepository.latestTranslation(for: record.id, script: .elder) != nil)

        _ = try repository.updateQuote(
            id: record.id,
            textLatin: "The king",
            author: "Runatal",
            source: nil,
            collection: .motivation,
            storedRunic: nil,
        )

        #expect(try translationRepository.latestTranslation(for: record.id, script: .elder) == nil)
    }

    @Test
    func hideRestoreAndArchiveQueriesTrackArchiveState() throws {
        let (repository, _) = try makeRepository()

        let record = try repository.createQuote(
            textLatin: "Wisdom walks quietly",
            author: "Runatal",
            source: nil,
            collection: .stoic,
            storedRunic: nil,
        )

        let hiddenRecord = try repository.hideQuote(id: record.id)
        #expect(hiddenRecord.isHidden)
        #expect(!hiddenRecord.isDeleted)
        #expect(try repository.allQuotes().allSatisfy { $0.id != record.id })

        let archived = try repository.archivedQuotes()
        #expect(archived.map(\.id) == [record.id])

        let restored = try repository.restoreQuote(id: record.id)
        #expect(!restored.isHidden)
        #expect(!restored.isDeleted)
        #expect(try repository.quote(id: record.id)?.id == record.id)
    }

    @Test
    func softDeleteAndEraseRemoveQuoteFromArchive() throws {
        let (repository, _) = try makeRepository()

        let record = try repository.createQuote(
            textLatin: "The mountain remembers",
            author: "Runatal",
            source: nil,
            collection: .tolkien,
            storedRunic: nil,
        )

        let deleted = try repository.softDeleteQuote(
            id: record.id,
            deletedAt: Date(timeIntervalSince1970: 1_700_000_000),
        )
        #expect(deleted.isDeleted)
        #expect(deleted.deletedAt != nil)
        #expect(try repository.archivedQuotes().map(\.id) == [record.id])

        try repository.eraseQuote(id: record.id)

        #expect(try repository.quote(id: record.id) == nil)
        #expect(try repository.archivedQuotes().isEmpty)
    }

    @Test
    func quoteOfTheDayThrowsWhenNoQuotes() throws {
        let (repository, _) = try makeRepository()

        var didThrow = false
        do {
            _ = try repository.quoteOfTheDay(for: .elder)
        } catch {
            didThrow = true
            #expect(error is QuoteRepositoryError)
        }

        #expect(didThrow)
    }

    @Test
    func randomQuoteThrowsWhenNoQuotes() throws {
        let (repository, _) = try makeRepository()

        var didThrow = false
        do {
            _ = try repository.randomQuote(for: .elder)
        } catch {
            didThrow = true
            #expect(error is QuoteRepositoryError)
        }

        #expect(didThrow)
    }

    @Test
    func seedMigrationPreservesUnrelatedCirthOverridesAndUnicodePunctuation() throws {
        let (repository, context) = try makeRepository()
        let override = try repository.createQuote(
            textLatin: "Custom text", author: "Audit", source: nil, collection: .motivation,
            storedRunic: RunicTextBundle(elder: nil, younger: nil, cirth: "EXACT-OUTPUT"),
        )
        let punctuation = try repository.createQuote(
            textLatin: "hello—world”,", author: "Audit", source: nil, collection: .motivation,
            storedRunic: nil,
        )
        let legacy = Quote(textLatin: "the king", author: "Legacy")
        legacy.runicCirth = "\u{E00B}\u{E003} \u{E004}\u{E006}\u{E024}"
        legacy.cirthEncodingRaw = nil
        context.insert(legacy)
        let versioned = Quote(textLatin: "Different font", author: "Audit")
        versioned.runicCirth = "\u{E001}"
        versioned.cirthEncodingRaw = "OTHER_EXPLICIT_FONT"
        context.insert(versioned)
        try context.save()

        try repository.seedIfNeeded()
        #expect(try repository.quote(id: override.id)?.runicCirth == "EXACT-OUTPUT")
        #expect(try repository.quote(id: punctuation.id)?.runicCirth == punctuation.runicCirth)
        let persistedLegacy = try #require(ModelContext(context.container).fetch(FetchDescriptor<Quote>()).first { $0.id == legacy.id })
        #expect(persistedLegacy.runicCirth == RunicTransliterator.transliterate(legacy.textLatin, to: .cirth).glyphOutput)
        #expect(persistedLegacy.cirthEncodingRaw == "CIRTH_CSUR_V1")
        #expect(versioned.runicCirth == "\u{E001}")
        try repository.seedIfNeeded()
        #expect(try repository.quote(id: override.id)?.runicCirth == "EXACT-OUTPUT")
    }

    @Test
    func failedUpdatePreservesQuoteAndCacheWithoutSavingOtherContexts() throws {
        let (repository, context) = try makeRepository()
        let original = try repository.createQuote(
            textLatin: "Original text", author: "Audit", source: nil, collection: .motivation,
            translations: [TestSupport.makeTranslationResult(sourceText: "Original text", script: .elder)],
        )
        let failing = SwiftDataQuoteRepository(modelContext: context, commit: { _ in throw TestError(message: "save failed") })
        context.insert(Quote(textLatin: "Unrelated pending work", author: "Audit"))
        #expect(throws: TestError.self) {
            try failing.updateQuote(id: original.id, textLatin: "Changed text", author: "Audit", source: nil, collection: .stoic)
        }
        #expect(try repository.quote(id: original.id)?.textLatin == "Original text")
        let persisted = ModelContext(context.container)
        #expect(try persisted.fetchCount(FetchDescriptor<Quote>()) == 1)
        #expect(try persisted.fetchCount(FetchDescriptor<TranslationRecord>()) == 1)
        #expect(context.hasChanges)
        _ = try repository.updateQuote(id: original.id, textLatin: "Changed text", author: "Audit", source: nil, collection: .stoic)
        #expect(try ModelContext(context.container).fetchCount(FetchDescriptor<TranslationRecord>()) == 0)
    }

    @Test
    func failedStructuredCreatePersistsNeitherQuoteNorCacheAndCanRetry() throws {
        let (repository, context) = try makeRepository()
        let failing = SwiftDataQuoteRepository(modelContext: context, commit: { _ in throw TestError(message: "save failed") })
        let result = TestSupport.makeTranslationResult(script: .elder)
        #expect(throws: TestError.self) {
            try failing.createQuote(textLatin: result.sourceText, author: "Audit", source: nil, collection: .stoic, translations: [result])
        }
        let persisted = ModelContext(context.container)
        #expect(try persisted.fetchCount(FetchDescriptor<Quote>()) == 0)
        #expect(try persisted.fetchCount(FetchDescriptor<TranslationRecord>()) == 0)
        _ = try repository.createQuote(textLatin: result.sourceText, author: "Audit", source: nil, collection: .stoic, translations: [result])
        #expect(try ModelContext(context.container).fetchCount(FetchDescriptor<Quote>()) == 1)
        #expect(try ModelContext(context.container).fetchCount(FetchDescriptor<TranslationRecord>()) == 1)
    }

    @Test
    func failedPurgePreservesAllQuotesCachesAndBookmarks() throws {
        let (repository, context) = try makeRepository()
        let first = try repository.createQuote(textLatin: "First", author: "Audit", source: nil, collection: .stoic, translations: [TestSupport.makeTranslationResult(sourceText: "First")])
        let second = try repository.createQuote(textLatin: "Second", author: "Audit", source: nil, collection: .stoic, translations: [TestSupport.makeTranslationResult(sourceText: "Second")])
        let oldDate = Date(timeIntervalSince1970: 100)
        _ = try repository.softDeleteQuote(id: first.id, deletedAt: oldDate)
        _ = try repository.softDeleteQuote(id: second.id, deletedAt: oldDate)
        let preferences = SwiftDataUserPreferencesRepository(modelContext: context)
        try preferences.apply([.toggleSavedQuote(first.id), .toggleSavedQuote(second.id)])
        let failing = SwiftDataQuoteRepository(modelContext: context, commit: { _ in throw TestError(message: "save failed") })
        #expect(throws: TestError.self) { try failing.purgeDeletedQuotes(before: Date()) }
        #expect(try repository.archivedQuotes().count == 2)
        #expect(try ModelContext(context.container).fetchCount(FetchDescriptor<TranslationRecord>()) == 2)
        #expect(try preferences.snapshot().savedQuoteIDs == [first.id, second.id])
        #expect(try repository.purgeDeletedQuotes(before: Date()) == 2)
        #expect(try repository.archivedQuotes().isEmpty)
        #expect(try ModelContext(context.container).fetchCount(FetchDescriptor<TranslationRecord>()) == 0)
        #expect(try preferences.snapshot().savedQuoteIDs.isEmpty)
    }

    private func makeRepository(seedData: Bool = false) throws -> (SwiftDataQuoteRepository, ModelContext) {
        let context = try TestSupport.makeModelContext()
        let repository = SwiftDataQuoteRepository(modelContext: context)
        if seedData {
            try repository.seedIfNeeded()
        }
        return (repository, context)
    }
}
