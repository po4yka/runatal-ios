//
//  QuoteProviderTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation
@testable import RunicQuotes
import Testing

@Suite(.serialized, .tags(.actors))
struct QuoteProviderTests {
    @Test
    func forwardsAllRepositoryCalls() async throws {
        let repository = TestQuoteRepository()
        let quote = TestSupport.makeQuoteRecord()
        repository.quoteOfTheDayQuote = quote
        repository.randomQuoteQueue = [quote]
        repository.allQuotesValue = [quote]
        repository.archivedQuotesValue = [quote]
        repository.quoteByID[quote.id] = quote
        repository.purgeDeletedQuotesValue = 3

        let provider = QuoteProvider(repository: repository)

        try await provider.seedIfNeeded()
        #expect(try await provider.quoteOfTheDay(for: .elder).id == quote.id)
        #expect(try await provider.randomQuote(for: .younger).id == quote.id)
        #expect(try await provider.allQuotes().map(\.id) == [quote.id])
        #expect(try await provider.quote(id: quote.id)?.id == quote.id)
        #expect(try await provider.archivedQuotes().map(\.id) == [quote.id])
        #expect(try await provider.hideQuote(id: quote.id).isHidden)
        #expect(try await provider.softDeleteQuote(id: quote.id, deletedAt: .now).isDeleted)
        #expect(try await provider.restoreQuote(id: quote.id).id == quote.id)
        try await provider.eraseQuote(id: quote.id)
        #expect(try await provider.purgeDeletedQuotes(before: .now) == 3)

        #expect(repository.seedCallCount == 1)
        #expect(repository.quoteOfTheDayScripts == [.elder])
        #expect(repository.randomQuoteScripts == [.younger])
        #expect(repository.hiddenQuoteIDs == [quote.id])
        #expect(repository.softDeletedQuoteIDs == [quote.id])
        #expect(repository.restoredQuoteIDs == [quote.id])
        #expect(repository.erasedQuoteIDs == [quote.id])
        #expect(repository.purgeCutoffDates.count == 1)
    }

    @Test
    func propagatesRepositoryErrors() async {
        let repository = TestQuoteRepository()
        repository.quoteOfTheDayError = TestError(message: "quote failed")
        let provider = QuoteProvider(repository: repository)

        var didThrow = false
        do {
            _ = try await provider.quoteOfTheDay(for: .elder)
        } catch {
            didThrow = true
            #expect((error as? TestError)?.message == "quote failed")
        }

        #expect(didThrow)
    }
}
