//
//  QuoteQueryTests.swift
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
struct QuoteQueryTests {
    @Test
    func limitedDailyAndRandomQueriesRespectSharedVisibleOrdering() throws {
        let context = try TestSupport.makeModelContext()
        let repository = SwiftDataQuoteRepository(modelContext: context)
        try repository.seedIfNeeded()
        let visible = try repository.allQuotes()
        let expected = visible[AppConstants.dailyQuoteIndex(totalQuotes: visible.count)]
        #expect(try repository.quoteOfTheDay(for: .elder).id == expected.id)
        for quote in visible where quote.id != expected.id {
            _ = try repository.hideQuote(id: quote.id)
        }
        #expect(try repository.randomQuote(for: .elder).id == expected.id)
        #expect(try repository.quoteOfTheDay(for: .elder).id == expected.id)
    }

}
