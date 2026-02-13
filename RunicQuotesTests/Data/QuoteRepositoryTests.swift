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
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var repository: SwiftDataQuoteRepository!

    override func setUpWithError() throws {
        // Create in-memory container for testing
        let schema = Schema([Quote.self, UserPreferences.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: config)
        modelContext = ModelContext(modelContainer)
        repository = SwiftDataQuoteRepository(modelContext: modelContext)
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
        repository = nil
    }

    // MARK: - Seeding Tests

    func testSeedIfNeededCreatesQuotes() async throws {
        // Given: Empty database
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
        try repository.seedIfNeeded()

        // When: Fetching quote of the day multiple times
        let quote1 = try repository.quoteOfTheDay(for: .elder)
        let quote2 = try repository.quoteOfTheDay(for: .elder)

        // Then: Should return same quote
        XCTAssertEqual(quote1.id, quote2.id, "Quote of the day should be deterministic")
    }

    func testQuoteOfTheDayWorksWithAllScripts() async throws {
        // Given: Seeded database
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
        try repository.seedIfNeeded()

        // When: Fetching for Elder Futhark
        let quote = try repository.quoteOfTheDay(for: .elder)

        // Then: Should have Elder Futhark transliteration
        XCTAssertNotNil(quote.runicElder, "Should have Elder transliteration")
    }

    // MARK: - Random Quote Tests

    func testRandomQuoteReturnsQuote() async throws {
        // Given: Seeded database
        try repository.seedIfNeeded()

        // When: Fetching random quote
        let quote = try repository.randomQuote(for: .elder)

        // Then: Should return valid quote
        XCTAssertFalse(quote.textLatin.isEmpty, "Quote should have text")
        XCTAssertFalse(quote.author.isEmpty, "Quote should have author")
    }

    func testRandomQuoteCanReturnDifferentQuotes() async throws {
        // Given: Seeded database with multiple quotes
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
        try repository.seedIfNeeded()

        // When: Fetching all quotes
        let quotes = try repository.allQuotes()

        // Then: Should return all seeded quotes
        XCTAssertGreaterThan(quotes.count, 0, "Should have quotes")
        XCTAssertEqual(quotes.count, 40, "Should have all 40 seed quotes")
    }

    func testAllQuotesReturnsSortedByCreatedAt() async throws {
        // Given: Seeded database
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

    // MARK: - Error Cases

    func testQuoteOfTheDayThrowsWhenNoQuotes() async throws {
        // Given: Empty database (not seeded)

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
        try repository.seedIfNeeded()

        measure {
            _ = try? repository.quoteOfTheDay(for: .elder)
        }
    }

    func testRandomQuotePerformance() async throws {
        try repository.seedIfNeeded()

        measure {
            _ = try? repository.randomQuote(for: .elder)
        }
    }
}
