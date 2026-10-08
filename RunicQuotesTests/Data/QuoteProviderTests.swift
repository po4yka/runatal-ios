//
//  QuoteProviderTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation
@testable import RunicQuotes
import SwiftData
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

        let provider = try QuoteProvider(modelContainer: TestSupport.makeModelContainer(), repositoryFactory: { _ in repository })

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
    func propagatesRepositoryErrors() async throws {
        let repository = TestQuoteRepository()
        repository.quoteOfTheDayError = TestError(message: "quote failed")
        let provider = try QuoteProvider(modelContainer: TestSupport.makeModelContainer(), repositoryFactory: { _ in repository })

        var didThrow = false
        do {
            _ = try await provider.quoteOfTheDay(for: .elder)
        } catch {
            didThrow = true
            #expect((error as? TestError)?.message == "quote failed")
        }

        #expect(didThrow)
    }

    @MainActor
    @Test
    func mainContextEditsAreVisibleThroughExistingProvider() async throws {
        let container = try TestSupport.makeModelContainer()
        let uiRepository = SwiftDataQuoteRepository(modelContext: container.mainContext)
        let quote = try uiRepository.createQuote(
            textLatin: "The first reading",
            author: "Runatal",
            source: nil,
            collection: .motivation,
            storedRunic: nil,
        )
        let provider = QuoteProvider(modelContainer: container)
        #expect(try await provider.quote(id: quote.id)?.textLatin == "The first reading")

        _ = try uiRepository.updateQuote(
            id: quote.id,
            textLatin: "The revised reading",
            author: "Runatal",
            source: nil,
            collection: .stoic,
            storedRunic: nil,
        )

        let updated = try await provider.quote(id: quote.id)
        #expect(updated?.textLatin == "The revised reading")
        #expect(updated?.collection == .stoic)
    }

    @MainActor
    @Test
    func actorMutationPersistsForAnotherContext() async throws {
        let container = try TestSupport.makeModelContainer()
        let uiRepository = SwiftDataQuoteRepository(modelContext: container.mainContext)
        let quote = try uiRepository.createQuote(
            textLatin: "The hidden reading",
            author: "Runatal",
            source: nil,
            collection: .motivation,
            storedRunic: nil,
        )
        let provider = QuoteProvider(modelContainer: container)

        #expect(try await provider.hideQuote(id: quote.id).isHidden)

        let persistedRepository = SwiftDataQuoteRepository(modelContext: ModelContext(container))
        #expect(try persistedRepository.quote(id: quote.id)?.isHidden == true)
        #expect(try persistedRepository.allQuotes().isEmpty)
    }
}
