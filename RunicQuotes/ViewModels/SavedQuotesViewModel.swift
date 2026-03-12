//
//  SavedQuotesViewModel.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
//

import Foundation
import SwiftUI
import SwiftData
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

    private var modelContext: ModelContext
    private var quoteProvider: QuoteProvider
    private var preferences: UserPreferences?
    private var isConfiguredWithEnvironmentContext = false

    private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "SavedQuotesVM")

    // MARK: - Computed Properties

    /// Number of currently saved quotes.
    var savedCount: Int {
        state.savedQuotes.count
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        let repository = SwiftDataQuoteRepository(modelContext: modelContext)
        self.quoteProvider = QuoteProvider(repository: repository)
    }

    // MARK: - Public API

    /// Rebind dependencies to the environment-provided context once the view is mounted.
    func configureIfNeeded(modelContext: ModelContext) {
        guard !isConfiguredWithEnvironmentContext else { return }

        self.modelContext = modelContext
        let repository = SwiftDataQuoteRepository(modelContext: modelContext)
        self.quoteProvider = QuoteProvider(repository: repository)
        isConfiguredWithEnvironmentContext = true
    }

    /// Load saved quotes when view appears.
    func onAppear() {
        Task {
            await loadSavedQuotes()
        }
    }

    /// Toggle the saved state for a quote and reload the list.
    func toggleSaved(_ quoteID: UUID) {
        guard let preferences else { return }

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
        state.isLoading = true
        state.errorMessage = nil

        do {
            preferences = try UserPreferences.getOrCreate(in: modelContext)
            let savedIDs = preferences?.savedQuoteIDs ?? []

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
            try modelContext.save()
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
        return SavedQuotesViewModel(modelContext: container.mainContext)
    }
}
