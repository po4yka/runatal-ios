//
//  ArchiveViewModelTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation
@testable import RunicQuotes
import Testing

@MainActor
@Suite(.serialized, .tags(.viewModel))
struct ArchiveViewModelTests {
    @Test
    func onAppearLoadsArchivedQuotesAndComputesCounts() async {
        let hidden = TestSupport.makeQuoteRecord(text: "Hidden", author: "Virgil", isHidden: true)
        let deleted = TestSupport.makeQuoteRecord(text: "Deleted", author: "Tolkien", isDeleted: true, deletedAt: .now)

        let repository = TestQuoteRepository()
        repository.archivedQuotesValue = [hidden, deleted]
        let viewModel = ArchiveViewModel(quoteProvider: QuoteProvider(repository: repository))

        viewModel.onAppear()

        #expect(await TestSupport.eventually { !viewModel.state.isLoading })
        #expect(viewModel.hasArchivedQuotes)
        #expect(viewModel.filteredQuotes.count == 2)
        #expect(viewModel.countLabel == "2 archived items")

        viewModel.updateFilter(.hidden)
        #expect(viewModel.filteredQuotes.map(\.id) == [hidden.id])
        #expect(viewModel.countLabel == "1 hidden quote")

        viewModel.updateFilter(.deleted)
        #expect(viewModel.filteredQuotes.map(\.id) == [deleted.id])
        #expect(viewModel.countLabel == "1 deleted quote")
    }

    @Test
    func restoreQuoteReloadsArchive() async {
        let quote = TestSupport.makeQuoteRecord(isDeleted: true, deletedAt: .now)
        let repository = TestQuoteRepository()
        repository.archivedQuotesValue = [quote]
        repository.quoteByID[quote.id] = quote

        let viewModel = ArchiveViewModel(quoteProvider: QuoteProvider(repository: repository))
        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })

        viewModel.restoreQuote(quote.id)

        #expect(await TestSupport.eventually {
            repository.restoredQuoteIDs == [quote.id] && repository.archivedQuotesCallCount >= 2
        })
        #expect(viewModel.state.errorMessage == nil)
    }

    @Test
    func unhideQuoteDelegatesToRestore() async {
        let quote = TestSupport.makeQuoteRecord(isHidden: true)
        let repository = TestQuoteRepository()
        repository.archivedQuotesValue = [quote]
        repository.quoteByID[quote.id] = quote

        let viewModel = ArchiveViewModel(quoteProvider: QuoteProvider(repository: repository))
        viewModel.unhideQuote(quote.id)

        #expect(await TestSupport.eventually { repository.restoredQuoteIDs == [quote.id] })
    }

    @Test
    func eraseQuoteReloadsArchive() async {
        let quote = TestSupport.makeQuoteRecord(isDeleted: true, deletedAt: .now)
        let repository = TestQuoteRepository()
        repository.archivedQuotesValue = [quote]

        let viewModel = ArchiveViewModel(quoteProvider: QuoteProvider(repository: repository))
        viewModel.eraseQuote(quote.id)

        #expect(await TestSupport.eventually {
            repository.erasedQuoteIDs == [quote.id] && repository.archivedQuotesCallCount >= 1
        })
    }

    @Test
    func restoreQuoteSurfacesErrors() async {
        let repository = TestQuoteRepository()
        repository.restoreError = TestError(message: "restore failed")
        let viewModel = ArchiveViewModel(quoteProvider: QuoteProvider(repository: repository))

        viewModel.restoreQuote(UUID())

        #expect(await TestSupport.eventually { viewModel.state.errorMessage != nil })
        #expect(viewModel.state.errorMessage == "Failed to restore quote: restore failed")
    }
}
