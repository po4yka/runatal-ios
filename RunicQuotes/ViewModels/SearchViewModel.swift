//
//  SearchViewModel.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
//

import Foundation
import SwiftUI

/// ViewModel for the search screen, decoupling search/filter logic from SwiftData.
@MainActor
final class SearchViewModel: ObservableObject {
    // MARK: - State

    struct State: Sendable {
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
        state.isLoading = true
        state.errorMessage = nil
        Task {
            await loadQuotes()
        }
    }

    /// Update the search text and recompute filtered results.
    func updateSearchText(_ text: String) {
        state.searchText = text
        state.isSearchActive = !text.isEmpty
        applyFilters()
    }

    /// Toggle the selected collection filter and recompute results.
    func updateSelectedCollection(_ collection: QuoteCollection?) {
        if state.selectedCollection == collection {
            state.selectedCollection = nil
        } else {
            state.selectedCollection = collection
        }
        applyFilters()
    }

    /// Reset search state to initial values.
    func clearSearch() {
        state.searchText = ""
        state.selectedCollection = nil
        state.isSearchActive = false
        state.filteredQuotes = []
    }

    // MARK: - Private Methods

    private func loadQuotes() async {
        do {
            cachedQuotes = try await quoteProvider.allQuotes()
            applyFilters()
            state.isLoading = false
        } catch {
            state.errorMessage = error.localizedDescription
            state.isLoading = false
        }
    }

    private func applyFilters() {
        guard state.isSearchActive else {
            state.filteredQuotes = []
            return
        }

        var results = cachedQuotes

        if let collection = state.selectedCollection, collection != .all {
            results = results.filter { $0.collection == collection }
        }

        let query = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        state.filteredQuotes = results.filter { quote in
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
