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
    func onAppearLoadsArchivedQuotesAndComputesCounts() async throws {
        let hidden = TestSupport.makeQuoteRecord(text: "Hidden", author: "Virgil", isHidden: true)
        let deleted = TestSupport.makeQuoteRecord(text: "Deleted", author: "Tolkien", isDeleted: true, deletedAt: .now)

        let repository = TestQuoteRepository()
        repository.archivedQuotesValue = [hidden, deleted]
        let viewModel = try ArchiveViewModel(quoteProvider: QuoteProvider(modelContainer: TestSupport.makeModelContainer(), repositoryFactory: { _ in repository }))

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
    func successfulRestoreRemovesArchiveRowAndPreservesPersistedQuoteID() async throws {
        let context = try TestSupport.makeModelContext()
        let repository = SwiftDataQuoteRepository(modelContext: context)
        let quote = try repository.createQuote(textLatin: "Restored passage", author: "Reader", source: nil, collection: .stoic, storedRunic: nil, translations: [])
        _ = try repository.softDeleteQuote(id: quote.id, deletedAt: Date())
        let viewModel = ArchiveViewModel(quoteProvider: QuoteProvider(modelContainer: context.container))
        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })
        #expect(viewModel.state.archivedQuotes.map(\.id) == [quote.id])
        #expect(await viewModel.restoreQuote(quote.id))
        #expect(viewModel.state.archivedQuotes.isEmpty)
        let restored = try #require(try repository.quote(id: quote.id))
        #expect(!restored.isDeleted)
        #expect(!restored.isHidden)
        #expect(restored.textLatin == quote.textLatin)
    }

    @Test
    func successfulUnhideRemovesArchiveRowAndRestoresVisibility() async throws {
        let context = try TestSupport.makeModelContext()
        let repository = SwiftDataQuoteRepository(modelContext: context)
        let quote = try repository.createQuote(textLatin: "Hidden passage", author: "Reader", source: nil, collection: .stoic, storedRunic: nil, translations: [])
        _ = try repository.hideQuote(id: quote.id)
        let viewModel = ArchiveViewModel(quoteProvider: QuoteProvider(modelContainer: context.container))
        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })
        #expect(await viewModel.unhideQuote(quote.id))
        #expect(viewModel.state.archivedQuotes.isEmpty)
        #expect(try repository.allQuotes().map(\.id) == [quote.id])
    }

    @Test
    func successfulEraseRemovesArchiveRowAndPersistedQuote() async throws {
        let context = try TestSupport.makeModelContext()
        let repository = SwiftDataQuoteRepository(modelContext: context)
        let quote = try repository.createQuote(textLatin: "Erased passage", author: "Reader", source: nil, collection: .stoic, storedRunic: nil, translations: [])
        _ = try repository.softDeleteQuote(id: quote.id, deletedAt: Date())
        let viewModel = ArchiveViewModel(quoteProvider: QuoteProvider(modelContainer: context.container))
        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })
        #expect(await viewModel.eraseQuote(quote.id))
        #expect(viewModel.state.archivedQuotes.isEmpty)
        #expect(try repository.quote(id: quote.id) == nil)
    }

    @Test
    func failedRestoreReturnsFalseKeepsArchivedRecordAndShowsError() async throws {
        let context = try TestSupport.makeModelContext()
        let repository = SwiftDataQuoteRepository(modelContext: context)
        let quote = try repository.createQuote(textLatin: "Archived passage", author: "Reader", source: nil, collection: .stoic, storedRunic: nil, translations: [])
        _ = try repository.softDeleteQuote(id: quote.id, deletedAt: Date())
        let provider = QuoteProvider(modelContainer: context.container, repositoryFactory: { context in
            SwiftDataQuoteRepository(modelContext: context, commit: { _ in throw CocoaError(.fileWriteUnknown) })
        })
        let viewModel = ArchiveViewModel(quoteProvider: provider)
        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })
        #expect(await !viewModel.restoreQuote(quote.id))
        #expect(viewModel.state.archivedQuotes.map(\.id) == [quote.id])
        #expect(viewModel.state.errorMessage != nil)
        #expect(viewModel.state.pendingActionIDs.isEmpty)
        #expect(try repository.quote(id: quote.id)?.isDeleted == true)
    }
}
