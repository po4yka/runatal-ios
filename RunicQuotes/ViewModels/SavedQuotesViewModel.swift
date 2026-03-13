//
//  SavedQuotesViewModel.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
//

import Foundation
import SwiftUI
import os

/// ViewModel for the saved quotes screen
@MainActor
final class SavedQuotesViewModel: ObservableObject {
    // MARK: - State

    struct State: Sendable {
        var savedQuotes: [QuoteRecord] = []
        var isLoading: Bool = false
        var errorMessage: String?
    }

    @Published private(set) var state = State()

    // MARK: - Dependencies

    private let quoteProvider: QuoteProvider
    private let preferencesRepository: any UserPreferencesRepository
    private var preferences = UserPreferencesSnapshot()

    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "SavedQuotesVM")

    // MARK: - Computed Properties

    /// Number of currently saved quotes.
    var savedCount: Int {
        state.savedQuotes.count
    }

    // MARK: - Initialization

    init(
        quoteProvider: QuoteProvider,
        preferencesRepository: any UserPreferencesRepository
    ) {
        self.quoteProvider = quoteProvider
        self.preferencesRepository = preferencesRepository
    }

    /// Load saved quotes when view appears.
    func onAppear() {
        state.isLoading = true
        state.errorMessage = nil
        Task {
            await loadSavedQuotes()
        }
    }

    /// Toggle the saved state for a quote and reload the list.
    func toggleSaved(_ quoteID: UUID) {
        preferences.toggleSavedQuote(quoteID)
        persistChanges()

        // Remove the quote from the local list immediately
        state.savedQuotes.removeAll { $0.id == quoteID }
    }

    /// Return copy-ready text for a saved quote.
    func copyQuoteText(_ quote: QuoteRecord) -> String {
        "\"\(quote.textLatin)\" -- \(quote.author)"
    }

    // MARK: - Private Methods

    private func loadSavedQuotes() async {
        do {
            preferences = try preferencesRepository.snapshot()
            let savedIDs = preferences.savedQuoteIDs

            let allQuotes = try await quoteProvider.allQuotes()
            state.savedQuotes = allQuotes.filter { savedIDs.contains($0.id) }
            state.isLoading = false
        } catch {
            logger.error("Failed to load saved quotes: \(error.localizedDescription)")
            state.errorMessage = "Failed to load saved quotes: \(error.localizedDescription)"
            state.isLoading = false
        }
    }

    private func persistChanges() {
        do {
            try preferencesRepository.save(preferences)
        } catch {
            state.errorMessage = "Failed to save changes: \(error.localizedDescription)"
        }
    }
}

// MARK: - Preview Helper

extension SavedQuotesViewModel {
    /// Create a view model for SwiftUI previews
    static func preview() -> SavedQuotesViewModel {
        let container = ModelContainerHelper.createPlaceholderContainer()
        let preferencesRepository = SwiftDataUserPreferencesRepository(modelContext: container.mainContext)
        let quoteRepository = SwiftDataQuoteRepository(modelContext: container.mainContext)
        return SavedQuotesViewModel(
            quoteProvider: QuoteProvider(repository: quoteRepository),
            preferencesRepository: preferencesRepository
        )
    }
}
