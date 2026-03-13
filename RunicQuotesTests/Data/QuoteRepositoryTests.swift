//
//  QuoteRepositoryTests.swift
//  RunicQuotesTests
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import SwiftData
import Testing
@testable import RunicQuotes

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
            ids.insert(try repository.randomQuote(for: .elder).id)
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
                cirth: "CIRTH-OVERRIDE"
            )
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
            storedRunic: nil
        )
        try translationRepository.cache(
            result: TestSupport.makeTranslationResult(script: .elder, glyphOutput: "ᚹᚢᛚᚠᚨᛉ"),
            for: record.id,
            sourceText: record.textLatin
        )

        #expect(try translationRepository.latestTranslation(for: record.id, script: .elder) != nil)

        _ = try repository.updateQuote(
            id: record.id,
            textLatin: "The king",
            author: "Runatal",
            source: nil,
            collection: .motivation,
            storedRunic: nil
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
            storedRunic: nil
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
            storedRunic: nil
        )

        let deleted = try repository.softDeleteQuote(
            id: record.id,
            deletedAt: Date(timeIntervalSince1970: 1_700_000_000)
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

    private func makeRepository(seedData: Bool = false) throws -> (SwiftDataQuoteRepository, ModelContext) {
        let context = try TestSupport.makeModelContext()
        let repository = SwiftDataQuoteRepository(modelContext: context)
        if seedData {
            try repository.seedIfNeeded()
        }
        return (repository, context)
    }
}
