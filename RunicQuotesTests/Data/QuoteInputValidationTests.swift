//
//  QuoteInputValidationTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
@testable import RunicQuotes
import Testing

@MainActor
@Suite(.serialized, .tags(.repository))
struct QuoteInputValidationTests {
    @Test
    func createRejectsInvalidPublicInputWithoutPartialInsertion() throws {
        let context = try TestSupport.makeModelContext()
        let repository = SwiftDataQuoteRepository(modelContext: context)
        let invalidInputs: [(String, (String, QuoteCollection))] = [
            (" \n ", ("Reader", .stoic)),
            ("Passage", (" \n ", .stoic)),
            ("Passage", ("Reader", .all)),
            (String(repeating: "a", count: AppConstants.maxQuoteLength + 1), ("Reader", .stoic)),
        ]
        for (text, (author, collection)) in invalidInputs {
            #expect(throws: QuoteInputError.self) {
                try repository.createQuote(textLatin: text, author: author, source: nil, collection: collection, storedRunic: nil, translations: [])
            }
        }
        #expect(try repository.allQuotes().isEmpty)
    }

    @Test
    func invalidUpdatePreservesExistingQuoteAndExactRunicOutput() throws {
        let context = try TestSupport.makeModelContext()
        let repository = SwiftDataQuoteRepository(modelContext: context)
        let quote = try repository.createQuote(textLatin: "Passage", author: "Reader", source: nil, collection: .stoic, storedRunic: RunicTextBundle(elder: "ᚠᚢᚦ", younger: nil, cirth: nil), translations: [])
        #expect(throws: QuoteInputError.self) {
            try repository.updateQuote(id: quote.id, textLatin: "", author: "Reader", source: nil, collection: .stoic, storedRunic: nil)
        }
        let unchanged = try #require(try repository.quote(id: quote.id))
        #expect(unchanged.textLatin == quote.textLatin)
        #expect(unchanged.runicElder == quote.runicElder)
    }
}
