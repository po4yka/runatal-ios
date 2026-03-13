//
//  SavedQuotesViewModel.swift
//  RunicQuotes
//
//  Created by Claude on 12.03.26.
//

import Foundation
import os
import SwiftUI

/// ViewModel for the saved quotes screen
@MainActor
final class SavedQuotesViewModel: ObservableObject {
    // MARK: - State

    struct State {
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
        self.state.savedQuotes.count
    }

    // MARK: - Initialization

    init(
        quoteProvider: QuoteProvider,
        preferencesRepository: any UserPreferencesRepository,
    ) {
        self.quoteProvider = quoteProvider
        self.preferencesRepository = preferencesRepository
    }

    /// Load saved quotes when view appears.
    func onAppear() {
        self.state.isLoading = true
        self.state.errorMessage = nil
        Task {
            await self.loadSavedQuotes()
        }
    }

    /// Toggle the saved state for a quote and reload the list.
    func toggleSaved(_ quoteID: UUID) {
        self.preferences.toggleSavedQuote(quoteID)
        self.persistChanges()

        // Remove the quote from the local list immediately
        self.state.savedQuotes.removeAll { $0.id == quoteID }
    }

    /// Return copy-ready text for a saved quote.
    func copyQuoteText(_ quote: QuoteRecord) -> String {
        "\"\(quote.textLatin)\" -- \(quote.author)"
    }

    // MARK: - Private Methods

    private func loadSavedQuotes() async {
        do {
            self.preferences = try self.preferencesRepository.snapshot()
            let savedIDs = self.preferences.savedQuoteIDs

            let allQuotes = try await quoteProvider.allQuotes()
            self.state.savedQuotes = allQuotes.filter { savedIDs.contains($0.id) }
            self.state.isLoading = false
        } catch {
            self.logger.error("Failed to load saved quotes: \(error.localizedDescription)")
            self.state.errorMessage = "Failed to load saved quotes: \(error.localizedDescription)"
            self.state.isLoading = false
        }
    }

    private func persistChanges() {
        do {
            try self.preferencesRepository.save(self.preferences)
        } catch {
            self.state.errorMessage = "Failed to save changes: \(error.localizedDescription)"
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
            preferencesRepository: preferencesRepository,
        )
    }
}
