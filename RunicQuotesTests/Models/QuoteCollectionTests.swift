//
//  QuoteCollectionTests.swift
//  RunicQuotesTests
//
//  Created by Codex on 2026-02-13.
//

import XCTest
@testable import RunicQuotes

final class QuoteCollectionTests: XCTestCase {
    func testContainsUsesExplicitQuoteCollectionTag() {
        let quote = makeRecord(
            text: "Wisdom is welcome wherever it comes from.",
            author: "Old English Proverb",
            collection: .stoic
        )

        XCTAssertTrue(QuoteCollection.stoic.contains(quote))
        XCTAssertFalse(QuoteCollection.motivation.contains(quote))
        XCTAssertFalse(QuoteCollection.tolkien.contains(quote))
    }

    func testAllCollectionContainsAnyQuote() {
        let quote = makeRecord(
            text: "Fortune favors the bold.",
            author: "Virgil",
            collection: .stoic
        )

        XCTAssertTrue(QuoteCollection.all.contains(quote))
    }

    func testQuoteDefaultsToMotivationCollectionWhenMissing() {
        let quote = Quote(textLatin: "The only way out is through.", author: "Robert Frost")
        quote.collectionRaw = nil
        let record = QuoteRecord(from: quote)
        XCTAssertEqual(record.collection, .motivation)
    }

    func testQuoteCollectionRawValuesDecodeFromSeedTags() {
        XCTAssertEqual(QuoteCollection(rawValue: "Motivation"), .motivation)
        XCTAssertEqual(QuoteCollection(rawValue: "Stoic"), .stoic)
        XCTAssertEqual(QuoteCollection(rawValue: "Tolkien"), .tolkien)
    }

    private func makeRecord(text: String, author: String, collection: QuoteCollection) -> QuoteRecord {
        let quote = Quote(textLatin: text, author: author, collection: collection)
        return QuoteRecord(from: quote)
    }
}
