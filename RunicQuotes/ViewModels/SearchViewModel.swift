//
//  SearchViewModel.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
//

import Foundation
import SwiftUI
import SwiftData

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

    private var modelContext: ModelContext
    private var quoteProvider: QuoteProvider
    private var isConfiguredWithEnvironmentContext = false
    private var cachedQuotes: [QuoteRecord] = []

    // MARK: - Computed Properties

    /// Static suggestion keywords shown before the user types a query.
    var suggestionKeywords: [String] {
        ["Marcus Aurelius", "Tolkien", "courage", "strength", "wisdom", "hope"]
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        let repository = SwiftDataQuoteRepository(modelContext: modelContext)
        quoteProvider = QuoteProvider(repository: repository)
    }

    // MARK: - Public API

    /// Rebind dependencies to the environment-provided context once the view is mounted.
    func configureIfNeeded(modelContext: ModelContext) {
        guard !isConfiguredWithEnvironmentContext else { return }

        self.modelContext = modelContext
        let repository = SwiftDataQuoteRepository(modelContext: modelContext)
        quoteProvider = QuoteProvider(repository: repository)
        isConfiguredWithEnvironmentContext = true
    }

    /// Load all visible quotes into cache when the view appears.
    func onAppear() {
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
        state.isLoading = true
        state.errorMessage = nil

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
        return SearchViewModel(modelContext: container.mainContext)
    }
}
