//
//  SearchViewModel.swift
//  RunicQuotes
//
//  Created by Claude on 12.03.26.
//

import Foundation
import SwiftUI

/// ViewModel for the search screen, decoupling search/filter logic from SwiftData.
@MainActor
final class SearchViewModel: ObservableObject {
    // MARK: - State

    struct State {
        var filteredQuotes: [QuoteRecord] = []
        var isSearchActive: Bool = false
        var searchText: String = ""
        var selectedCollection: QuoteCollection?
        var isLoading: Bool = false
        var errorMessage: String?
    }

    @Published private(set) var state = State()

    // MARK: - Dependencies

    private let quoteProvider: QuoteProvider
    private var cachedQuotes: [QuoteRecord] = []

    // MARK: - Computed Properties

    /// Static suggestion keywords shown before the user types a query.
    var suggestionKeywords: [String] {
        ["Marcus Aurelius", "Tolkien", "courage", "strength", "wisdom", "hope"]
    }

    // MARK: - Initialization

    init(quoteProvider: QuoteProvider) {
        self.quoteProvider = quoteProvider
    }

    /// Load all visible quotes into cache when the view appears.
    func onAppear() {
        self.state.isLoading = true
        self.state.errorMessage = nil
        Task {
            await self.loadQuotes()
        }
    }

    /// Update the search text and recompute filtered results.
    func updateSearchText(_ text: String) {
        self.state.searchText = text
        self.state.isSearchActive = !text.isEmpty
        self.applyFilters()
    }

    /// Toggle the selected collection filter and recompute results.
    func updateSelectedCollection(_ collection: QuoteCollection?) {
        if self.state.selectedCollection == collection {
            self.state.selectedCollection = nil
        } else {
            self.state.selectedCollection = collection
        }
        self.applyFilters()
    }

    /// Reset search state to initial values.
    func clearSearch() {
        self.state.searchText = ""
        self.state.selectedCollection = nil
        self.state.isSearchActive = false
        self.state.filteredQuotes = []
    }

    // MARK: - Private Methods

    private func loadQuotes() async {
        do {
            self.cachedQuotes = try await self.quoteProvider.allQuotes()
            self.applyFilters()
            self.state.isLoading = false
        } catch {
            self.state.errorMessage = error.localizedDescription
            self.state.isLoading = false
        }
    }

    private func applyFilters() {
        guard self.state.isSearchActive else {
            self.state.filteredQuotes = []
            return
        }

        var results = self.cachedQuotes

        if let collection = state.selectedCollection, collection != .all {
            results = results.filter { $0.collection == collection }
        }

        let query = self.state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        self.state.filteredQuotes = results.filter { quote in
            quote.textLatin.localizedStandardContains(query)
                || quote.author.localizedStandardContains(query)
        }
    }
}

// MARK: - Preview Helper

extension SearchViewModel {
    /// Create a view model for SwiftUI previews
    static func preview() -> SearchViewModel {
        let container = ModelContainerHelper.createPlaceholderContainer()
        let quoteRepository = SwiftDataQuoteRepository(modelContext: container.mainContext)
        return SearchViewModel(quoteProvider: QuoteProvider(repository: quoteRepository))
    }
}
