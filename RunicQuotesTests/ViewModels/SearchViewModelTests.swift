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
    func onAppearLoadsQuotesAndFiltersBySearchText() async {
        let repository = TestQuoteRepository()
        repository.allQuotesValue = [
            TestSupport.makeQuoteRecord(text: "Fortune favors the bold", author: "Virgil", collection: .stoic),
            TestSupport.makeQuoteRecord(text: "The hidden road", author: "Tolkien", collection: .tolkien),
        ]
        let viewModel = SearchViewModel(quoteProvider: QuoteProvider(repository: repository))

        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })
        #expect(viewModel.state.errorMessage == nil)

        viewModel.updateSearchText("fortune")

        #expect(viewModel.state.isSearchActive)
        #expect(viewModel.state.filteredQuotes.count == 1)
        #expect(viewModel.state.filteredQuotes.first?.author == "Virgil")
    }

    @Test
    func selectedCollectionFiltersAndToggleClearsSelection() async {
        let repository = TestQuoteRepository()
        repository.allQuotesValue = [
            TestSupport.makeQuoteRecord(text: "Fortune favors the bold", author: "Virgil", collection: .stoic),
            TestSupport.makeQuoteRecord(text: "The hidden road", author: "Tolkien", collection: .tolkien),
        ]
        let viewModel = SearchViewModel(quoteProvider: QuoteProvider(repository: repository))

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
    func clearSearchResetsPresentationState() {
        let repository = TestQuoteRepository()
        repository.allQuotesValue = [TestSupport.makeQuoteRecord()]
        let viewModel = SearchViewModel(quoteProvider: QuoteProvider(repository: repository))

        viewModel.updateSearchText("wolf")
        viewModel.updateSelectedCollection(.stoic)
        viewModel.clearSearch()

        #expect(viewModel.state.searchText.isEmpty)
        #expect(viewModel.state.selectedCollection == nil)
        #expect(!viewModel.state.isSearchActive)
        #expect(viewModel.state.filteredQuotes.isEmpty)
    }

    @Test
    func onAppearSurfacesLoadingErrors() async {
        let repository = TestQuoteRepository()
        repository.allQuotesError = TestError(message: "load failed")
        let viewModel = SearchViewModel(quoteProvider: QuoteProvider(repository: repository))

        viewModel.onAppear()

        #expect(await TestSupport.eventually {
            !viewModel.state.isLoading && viewModel.state.errorMessage != nil
        })
        #expect(viewModel.state.errorMessage == "load failed")
    }
}
