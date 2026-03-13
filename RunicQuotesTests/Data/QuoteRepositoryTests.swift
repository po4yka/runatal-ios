//
//  QuoteRepositoryTests.swift
//  RunicQuotesTests
//
//  Created by Claude on 2025-11-15.
//

import XCTest
import SwiftData
@testable import RunicQuotes

final class QuoteRepositoryTests: XCTestCase {
    var modelContainer: ModelContainer?
    var modelContext: ModelContext?
    var repository: SwiftDataQuoteRepository?

    override func setUpWithError() throws {
        // Create in-memory container for testing
        let schema = Schema([Quote.self, UserPreferences.self, TranslationRecord.self, TranslationBackfillState.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        modelContainer = container
        let context = ModelContext(container)
        modelContext = context
        repository = SwiftDataQuoteRepository(modelContext: context)
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
        repository = nil
    }

    // MARK: - Seeding Tests

    func testSeedIfNeededCreatesQuotes() async throws {
        // Given: Empty database
        let modelContext = try XCTUnwrap(modelContext)
        let repository = try XCTUnwrap(repository)
        let initialCount = try modelContext.fetch(FetchDescriptor<Quote>()).count
        XCTAssertEqual(initialCount, 0, "Database should start empty")

        // When: Seeding
        try repository.seedIfNeeded()

        // Then: Quotes exist
        let finalCount = try modelContext.fetch(FetchDescriptor<Quote>()).count
        XCTAssertGreaterThan(finalCount, 0, "Database should contain quotes after seeding")
    }

    func testSeedIfNeededIdempotent() async throws {
        // Given: Already seeded database
        let modelContext = try XCTUnwrap(modelContext)
        let repository = try XCTUnwrap(repository)
        try repository.seedIfNeeded()
        let firstCount = try modelContext.fetch(FetchDescriptor<Quote>()).count

        // When: Seeding again
        try repository.seedIfNeeded()

        // Then: Count should not change
        let secondCount = try modelContext.fetch(FetchDescriptor<Quote>()).count
        XCTAssertEqual(firstCount, secondCount, "Seeding should be idempotent")
    }

    func testSeededQuotesHaveTransliterations() async throws {
        // Given: Seeded database
        let modelContext = try XCTUnwrap(modelContext)
        let repository = try XCTUnwrap(repository)
        try repository.seedIfNeeded()

        // When: Fetching quotes
        let quotes = try modelContext.fetch(FetchDescriptor<Quote>())

        // Then: Quotes have runic transliterations
        XCTAssertFalse(quotes.isEmpty, "Should have quotes")

        for quote in quotes.prefix(5) {
            XCTAssertNotNil(quote.runicElder, "Quote should have Elder Futhark")
            XCTAssertNotNil(quote.runicYounger, "Quote should have Younger Futhark")
            XCTAssertNotNil(quote.runicCirth, "Quote should have Cirth")
        }
    }

    func testSeededQuotesHaveCollectionTags() async throws {
        let modelContext = try XCTUnwrap(modelContext)
        let repository = try XCTUnwrap(repository)
        try repository.seedIfNeeded()

        let quotes = try modelContext.fetch(FetchDescriptor<Quote>())
        XCTAssertFalse(quotes.isEmpty, "Should have quotes")

        for quote in quotes {
            XCTAssertNotNil(quote.collectionRaw, "Quote should contain explicit collection tag")
            XCTAssertNotNil(QuoteCollection(rawValue: quote.collectionRaw ?? ""), "Collection tag should be valid")
        }
    }

    // MARK: - Quote of the Day Tests

    func testQuoteOfTheDayReturnsSameQuoteOnSameDay() async throws {
        // Given: Seeded database
        let repository = try XCTUnwrap(repository)
        try repository.seedIfNeeded()

        // When: Fetching quote of the day multiple times
        let quote1 = try repository.quoteOfTheDay(for: .elder)
        let quote2 = try repository.quoteOfTheDay(for: .elder)

        // Then: Should return same quote
        XCTAssertEqual(quote1.id, quote2.id, "Quote of the day should be deterministic")
    }

    func testQuoteOfTheDayWorksWithAllScripts() async throws {
        // Given: Seeded database
        let repository = try XCTUnwrap(repository)
        try repository.seedIfNeeded()

        // When: Fetching for each script
        let elder = try repository.quoteOfTheDay(for: .elder)
        let younger = try repository.quoteOfTheDay(for: .younger)
        let cirth = try repository.quoteOfTheDay(for: .cirth)

        // Then: All should succeed
        XCTAssertFalse(elder.textLatin.isEmpty, "Elder quote should have text")
        XCTAssertFalse(younger.textLatin.isEmpty, "Younger quote should have text")
        XCTAssertFalse(cirth.textLatin.isEmpty, "Cirth quote should have text")
    }

    func testQuoteOfTheDayReturnsQuoteWithCorrectScript() async throws {
        // Given: Seeded database
        let repository = try XCTUnwrap(repository)
        try repository.seedIfNeeded()

        // When: Fetching for Elder Futhark
        let quote = try repository.quoteOfTheDay(for: .elder)

        // Then: Should have Elder Futhark transliteration
        XCTAssertNotNil(quote.runicElder, "Should have Elder transliteration")
    }

    // MARK: - Random Quote Tests

    func testRandomQuoteReturnsQuote() async throws {
        // Given: Seeded database
        let repository = try XCTUnwrap(repository)
        try repository.seedIfNeeded()

        // When: Fetching random quote
        let quote = try repository.randomQuote(for: .elder)

        // Then: Should return valid quote
        XCTAssertFalse(quote.textLatin.isEmpty, "Quote should have text")
        XCTAssertFalse(quote.author.isEmpty, "Quote should have author")
    }

    func testRandomQuoteCanReturnDifferentQuotes() async throws {
        // Given: Seeded database with multiple quotes
        let repository = try XCTUnwrap(repository)
        try repository.seedIfNeeded()

        // When: Fetching multiple random quotes
        var quotes = Set<UUID>()
        for _ in 0..<10 {
            let quote = try repository.randomQuote(for: .elder)
            quotes.insert(quote.id)
        }

        // Then: Should have some variety (probabilistically)
        // With 40 quotes, 10 fetches should likely give us more than 1 unique quote
        XCTAssertGreaterThan(quotes.count, 1, "Random should return different quotes")
    }

    // MARK: - All Quotes Tests

    func testAllQuotesReturnsAllQuotes() async throws {
        // Given: Seeded database
        let repository = try XCTUnwrap(repository)
        try repository.seedIfNeeded()

        // When: Fetching all quotes
        let quotes = try repository.allQuotes()

        // Then: Should return all seeded quotes
        XCTAssertGreaterThan(quotes.count, 0, "Should have quotes")
        XCTAssertEqual(quotes.count, 40, "Should have all 40 seed quotes")
    }

    func testAllQuotesReturnsSortedByCreatedAt() async throws {
        // Given: Seeded database
        let repository = try XCTUnwrap(repository)
        try repository.seedIfNeeded()

        // When: Fetching all quotes
        let quotes = try repository.allQuotes()

        // Then: Should be sorted by creation date
        for i in 0..<(quotes.count - 1) {
            XCTAssertLessThanOrEqual(
                quotes[i].createdAt,
                quotes[i + 1].createdAt,
                "Quotes should be sorted by creation date"
            )
        }
    }

    func testCreateQuoteStoredRunicOverridesTransliteration() throws {
        let repository = try XCTUnwrap(repository)

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

        XCTAssertEqual(record.runicElder, "ELDER-OVERRIDE")
        XCTAssertNil(record.runicYounger)
        XCTAssertEqual(record.runicCirth, "CIRTH-OVERRIDE")
    }

    func testUpdateQuoteDeletesCachedTranslationsWhenTextChanges() throws {
        let repository = try XCTUnwrap(repository)
        let translationRepository = SwiftDataTranslationRepository(modelContext: try XCTUnwrap(modelContext))

        let record = try repository.createQuote(
            textLatin: "The wolf hunts at night",
            author: "Runatal",
            source: nil,
            collection: .motivation,
            storedRunic: nil
        )
        try translationRepository.cache(
            result: makeTranslationResult(script: .elder, glyphOutput: "ᚹᚢᛚᚠᚨᛉ"),
            for: record.id,
            sourceText: record.textLatin
        )

        XCTAssertNotNil(try translationRepository.latestTranslation(for: record.id, script: .elder))

        _ = try repository.updateQuote(
            id: record.id,
            textLatin: "The king",
            author: "Runatal",
            source: nil,
            collection: .motivation,
            storedRunic: nil
        )

        XCTAssertNil(try translationRepository.latestTranslation(for: record.id, script: .elder))
    }

    func testHideRestoreAndArchiveQueriesTrackArchiveState() throws {
        let repository = try XCTUnwrap(repository)

        let record = try repository.createQuote(
            textLatin: "Wisdom walks quietly",
            author: "Runatal",
            source: nil,
            collection: .stoic,
            storedRunic: nil
        )

        let hiddenRecord = try repository.hideQuote(id: record.id)
        XCTAssertTrue(hiddenRecord.isHidden)
        XCTAssertFalse(hiddenRecord.isDeleted)
        XCTAssertTrue(try repository.allQuotes().allSatisfy { $0.id != record.id })

        let archived = try repository.archivedQuotes()
        XCTAssertEqual(archived.map(\.id), [record.id])

        let restored = try repository.restoreQuote(id: record.id)
        XCTAssertFalse(restored.isHidden)
        XCTAssertFalse(restored.isDeleted)
        XCTAssertEqual(try repository.quote(id: record.id)?.id, record.id)
    }

    func testSoftDeleteAndEraseRemoveQuoteFromArchive() throws {
        let repository = try XCTUnwrap(repository)

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
        XCTAssertTrue(deleted.isDeleted)
        XCTAssertNotNil(deleted.deletedAt)
        XCTAssertEqual(try repository.archivedQuotes().map(\.id), [record.id])

        try repository.eraseQuote(id: record.id)

        XCTAssertNil(try repository.quote(id: record.id))
        XCTAssertTrue(try repository.archivedQuotes().isEmpty)
    }

    // MARK: - Error Cases

    func testQuoteOfTheDayThrowsWhenNoQuotes() async throws {
        // Given: Empty database (not seeded)
        let repository = try XCTUnwrap(repository)

        // When/Then: Should throw error
        do {
            _ = try repository.quoteOfTheDay(for: .elder)
            XCTFail("Should throw error when no quotes available")
        } catch {
            // Expected
            XCTAssertTrue(error is QuoteRepositoryError, "Should be QuoteRepositoryError")
        }
    }

    func testRandomQuoteThrowsWhenNoQuotes() async throws {
        // Given: Empty database (not seeded)
        let repository = try XCTUnwrap(repository)

        // When/Then: Should throw error
        do {
            _ = try repository.randomQuote(for: .elder)
            XCTFail("Should throw error when no quotes available")
        } catch {
            // Expected
            XCTAssertTrue(error is QuoteRepositoryError, "Should be QuoteRepositoryError")
        }
    }

    // MARK: - Performance Tests

    func testQuoteOfTheDayPerformance() async throws {
        let repository = try XCTUnwrap(repository)
        try repository.seedIfNeeded()

        measure {
            _ = try? repository.quoteOfTheDay(for: .elder)
        }
    }

    func testRandomQuotePerformance() async throws {
        let repository = try XCTUnwrap(repository)
        try repository.seedIfNeeded()

        measure {
            _ = try? repository.randomQuote(for: .elder)
        }
    }

    private func makeTranslationResult(script: RunicScript, glyphOutput: String) -> TranslationResult {
        TranslationResult(
            sourceText: "The wolf hunts at night",
            script: script,
            fidelity: .strict,
            derivationKind: .goldExample,
            historicalStage: script == .cirth ? .ereborEnglish : .oldNorse,
            normalizedForm: "normalized",
            diplomaticForm: "diplomatic",
            glyphOutput: glyphOutput,
            resolutionStatus: .reconstructed,
            confidence: 0.9,
            notes: ["note"],
            unresolvedTokens: [],
            provenance: [],
            tokenBreakdown: [],
            engineVersion: "test-engine",
            datasetVersion: "test-dataset"
        )
    }
}
