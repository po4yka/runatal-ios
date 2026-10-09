//
//  SearchViewModelTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

@testable import RunicQuotes
import Testing

@MainActor
@Suite(.serialized, .tags(.viewModel))
struct SearchViewModelTests {
    @Test
    func onAppearLoadsQuotesAndFiltersBySearchText() async throws {
        let repository = TestQuoteRepository()
        repository.allQuotesValue = [
            TestSupport.makeQuoteRecord(text: "Fortune favors the bold", author: "Virgil", collection: .stoic),
            TestSupport.makeQuoteRecord(text: "The hidden road", author: "Tolkien", collection: .tolkien),
        ]
        let viewModel = try SearchViewModel(quoteProvider: QuoteProvider(modelContainer: TestSupport.makeModelContainer(), repositoryFactory: { _ in repository }))

        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })
        #expect(viewModel.state.errorMessage == nil)

        viewModel.updateSearchText("fortune")

        #expect(viewModel.state.isSearchActive)
        #expect(viewModel.state.filteredQuotes.count == 1)
        #expect(viewModel.state.filteredQuotes.first?.author == "Virgil")
    }

    @Test
    func reappearanceRefreshesCreatedEditedAndDeletedSearchResults() async throws {
        let context = try TestSupport.makeModelContext()
        let repository = SwiftDataQuoteRepository(modelContext: context)
        let first = try repository.createQuote(textLatin: "A quiet source", author: "Reader", source: nil, collection: .motivation)
        let viewModel = SearchViewModel(quoteProvider: QuoteProvider(modelContainer: context.container))
        viewModel.updateSearchText("source")
        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })
        #expect(viewModel.state.filteredQuotes.map(\.id) == [first.id])
        let second = try repository.createQuote(textLatin: "Another source", author: "Reader", source: nil, collection: .motivation)
        _ = try repository.updateQuote(id: first.id, textLatin: "A changed passage", author: "Reader", source: nil, collection: .motivation)
        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })
        #expect(viewModel.state.filteredQuotes.map(\.id) == [second.id])
        _ = try repository.softDeleteQuote(id: second.id)
        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })
        #expect(viewModel.state.filteredQuotes.isEmpty)
    }

    @Test
    func selectedCollectionFiltersAndToggleClearsSelection() async throws {
        let repository = TestQuoteRepository()
        repository.allQuotesValue = [
            TestSupport.makeQuoteRecord(text: "Fortune favors the bold", author: "Virgil", collection: .stoic),
            TestSupport.makeQuoteRecord(text: "The hidden road", author: "Tolkien", collection: .tolkien),
        ]
        let viewModel = try SearchViewModel(quoteProvider: QuoteProvider(modelContainer: TestSupport.makeModelContainer(), repositoryFactory: { _ in repository }))

        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })
        viewModel.updateSearchText("the")
        viewModel.updateSelectedCollection(.tolkien)

        #expect(viewModel.state.selectedCollection == .tolkien)
        #expect(viewModel.state.filteredQuotes.count == 1)
        #expect(viewModel.state.filteredQuotes.first?.collection == .tolkien)

        viewModel.updateSelectedCollection(.tolkien)

        #expect(viewModel.state.selectedCollection == nil)
    }

    @Test
    func clearSearchResetsPresentationState() throws {
        let repository = TestQuoteRepository()
        repository.allQuotesValue = [TestSupport.makeQuoteRecord()]
        let viewModel = try SearchViewModel(quoteProvider: QuoteProvider(modelContainer: TestSupport.makeModelContainer(), repositoryFactory: { _ in repository }))

        viewModel.updateSearchText("wolf")
        viewModel.updateSelectedCollection(.stoic)
        viewModel.clearSearch()

        #expect(viewModel.state.searchText.isEmpty)
        #expect(viewModel.state.selectedCollection == nil)
        #expect(!viewModel.state.isSearchActive)
        #expect(viewModel.state.filteredQuotes.isEmpty)
    }

    @Test
    func onAppearSurfacesLoadingErrors() async throws {
        let repository = TestQuoteRepository()
        repository.allQuotesError = TestError(message: "load failed")
        let viewModel = try SearchViewModel(quoteProvider: QuoteProvider(modelContainer: TestSupport.makeModelContainer(), repositoryFactory: { _ in repository }))

        viewModel.onAppear()

        #expect(await TestSupport.eventually {
            !viewModel.state.isLoading && viewModel.state.errorMessage != nil
        })
        #expect(viewModel.state.errorMessage == "load failed")
    }
}
