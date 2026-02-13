//
//  QuoteViewModel.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import SwiftUI
import SwiftData

/// UI state for the quote view
struct QuoteUiState: Sendable {
    var runicText: String = ""
    var latinText: String = ""
    var author: String = ""
    var currentScript: RunicScript = .elder
    var currentFont: RunicFont = .noto
    var isLoading: Bool = true
    var errorMessage: String?
}

/// ViewModel for the main quote display screen
@MainActor
final class QuoteViewModel: ObservableObject {
    // MARK: - Published State

    @Published private(set) var state = QuoteUiState()

    // MARK: - Dependencies

    private var modelContext: ModelContext
    private var quoteProvider: QuoteProvider
    private var preferences: UserPreferences?
    private var isConfiguredWithEnvironmentContext = false

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        let repository = SwiftDataQuoteRepository(modelContext: modelContext)
        quoteProvider = QuoteProvider(repository: repository)
    }

    // MARK: - Public API

    /// Load initial quote when view appears
    func onAppear() {
        Task {
            await loadPreferences()
            await loadQuoteOfTheDay()
        }
    }

    /// Rebind dependencies to the environment-provided context once the view is mounted.
    func configureIfNeeded(modelContext: ModelContext) {
        guard !isConfiguredWithEnvironmentContext else { return }

        self.modelContext = modelContext
        let repository = SwiftDataQuoteRepository(modelContext: modelContext)
        quoteProvider = QuoteProvider(repository: repository)
        isConfiguredWithEnvironmentContext = true
    }

    /// Load the next random quote
    func onNextQuoteTapped() {
        Task {
            await loadRandomQuote()
        }
    }

    /// Change the current runic script
    func onScriptChanged(_ script: RunicScript) {
        Task {
            await updateScript(script)
        }
    }

    /// Change the current font
    func onFontChanged(_ font: RunicFont) {
        Task {
            await updateFont(font)
        }
    }

    /// Refresh the quote of the day
    func refresh() {
        Task {
            await loadQuoteOfTheDay()
        }
    }

    // MARK: - Private Methods

    private func loadPreferences() async {
        do {
            preferences = try UserPreferences.getOrCreate(in: modelContext)

            // Update state with preferences
            state.currentScript = preferences?.selectedScript ?? .elder
            state.currentFont = preferences?.selectedFont ?? .noto
        } catch {
            state.errorMessage = "Failed to load preferences: \(error.localizedDescription)"
        }
    }

    private func loadQuoteOfTheDay() async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            let quote = try await quoteProvider.quoteOfTheDay(for: state.currentScript)
            updateState(with: quote)
            state.isLoading = false
        } catch {
            state.errorMessage = error.localizedDescription
            state.isLoading = false
        }
    }

    private func loadRandomQuote() async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            let quote = try await quoteProvider.randomQuote(for: state.currentScript)
            updateState(with: quote)
            state.isLoading = false
        } catch {
            state.errorMessage = error.localizedDescription
            state.isLoading = false
        }
    }

    private func updateScript(_ script: RunicScript) async {
        // Update preferences
        preferences?.selectedScript = script
        try? modelContext.save()

        // Update state
        state.currentScript = script

        // Ensure font is compatible with script
        if !state.currentFont.isCompatible(with: script) {
            let recommendedFont = RunicFontConfiguration.recommendedFont(for: script)
            await updateFont(recommendedFont)
        }

        // Reload quote with new script
        await loadQuoteOfTheDay()
    }

    private func updateFont(_ font: RunicFont) async {
        // Verify compatibility
        guard font.isCompatible(with: state.currentScript) else {
            state.errorMessage = "\(font.displayName) is not compatible with \(state.currentScript.displayName)"
            return
        }

        // Update preferences
        preferences?.selectedFont = font
        try? modelContext.save()

        // Update state
        state.currentFont = font
    }

    private func updateState(with quote: QuoteRecord) {
        state.latinText = quote.textLatin
        state.author = quote.author

        // Get runic text for current script
        if let runicText = quote.runicText(for: state.currentScript) {
            state.runicText = runicText
        } else {
            // Fallback: compute on-demand if missing
            state.runicText = RunicTransliterator.transliterate(quote.textLatin, to: state.currentScript)
        }
    }
}

// MARK: - Preview Helper

extension QuoteViewModel {
    /// Create a view model for SwiftUI previews
    static func preview() -> QuoteViewModel {
        let container = ModelContainerHelper.createPlaceholderContainer()
        return QuoteViewModel(modelContext: container.mainContext)
    }
}
