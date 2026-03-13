//
//  QuoteCollectionTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.02.26.
//

@testable import RunicQuotes
import Testing

@Suite(.tags(.model))
struct QuoteCollectionTests {
    @Test
    func containsUsesExplicitQuoteCollectionTag() {
        let quote = self.makeRecord(
            text: "Wisdom is welcome wherever it comes from.",
            author: "Old English Proverb",
            collection: .stoic,
        )

        #expect(QuoteCollection.stoic.contains(quote))
        #expect(!QuoteCollection.motivation.contains(quote))
        #expect(!QuoteCollection.tolkien.contains(quote))
    }

    @Test
    func allCollectionContainsAnyQuote() {
        let quote = self.makeRecord(
            text: "Fortune favors the bold.",
            author: "Virgil",
            collection: .stoic,
        )

        #expect(QuoteCollection.all.contains(quote))
    }

    @Test
    func quoteDefaultsToMotivationCollectionWhenMissing() {
        let quote = Quote(textLatin: "The only way out is through.", author: "Robert Frost")
        quote.collectionRaw = nil

        #expect(QuoteRecord(from: quote).collection == .motivation)
    }

    @Test(arguments: [
        ("Motivation", QuoteCollection.motivation),
        ("Stoic", QuoteCollection.stoic),
        ("Tolkien", QuoteCollection.tolkien),
    ])
    func quoteCollectionRawValuesDecodeFromSeedTags(rawValue: String, expected: QuoteCollection) {
        #expect(QuoteCollection(rawValue: rawValue) == expected)
    }

    private func makeRecord(text: String, author: String, collection: QuoteCollection) -> QuoteRecord {
        let quote = Quote(textLatin: text, author: author, collection: collection)
        return QuoteRecord(from: quote)
    }
}
