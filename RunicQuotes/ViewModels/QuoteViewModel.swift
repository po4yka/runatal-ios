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
    var currentQuoteID: UUID?
    var isCurrentQuoteSaved: Bool = false
    var currentScript: RunicScript = .elder
    var currentFont: RunicFont = .noto
    var currentWidgetMode: WidgetMode = .daily
    var currentTheme: AppTheme = .obsidian
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

    /// Toggle save state for the currently visible quote.
    func onToggleSaveTapped() {
        guard let quoteID = state.currentQuoteID else { return }
        toggleSavedState(for: quoteID)
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

    /// Apply updated persisted preferences (e.g. after changes in Settings tab).
    func onPreferencesChanged() {
        Task {
            let previousScript = state.currentScript
            let previousMode = state.currentWidgetMode
            await loadPreferences()

            if previousScript != state.currentScript || previousMode != state.currentWidgetMode {
                await loadQuote(using: state.currentWidgetMode, updateContext: true)
            }
        }
    }

    /// Apply deep-link context from widget and open quote screen in matching state.
    func onOpenQuoteDeepLink(scriptRaw: String?, modeRaw: String?) {
        let script = parseScript(from: scriptRaw)
        let mode = parseMode(from: modeRaw)

        Task {
            await loadPreferences()

            if let script {
                applyScriptPreference(script)
            }

            if let mode {
                state.currentWidgetMode = mode
                preferences?.widgetMode = mode
            }

            persistPreferences()
            await loadQuote(using: mode ?? state.currentWidgetMode, updateContext: true)
        }
    }

    // MARK: - Private Methods

    private func loadPreferences() async {
        do {
            preferences = try UserPreferences.getOrCreate(in: modelContext)

            // Update state with preferences
            state.currentScript = preferences?.selectedScript ?? .elder
            state.currentFont = preferences?.selectedFont ?? .noto
            state.currentWidgetMode = preferences?.widgetMode ?? .daily
            state.currentTheme = preferences?.selectedTheme ?? .obsidian
            syncSavedStateForCurrentQuote()
        } catch {
            state.errorMessage = "Failed to load preferences: \(error.localizedDescription)"
        }
    }

    private func loadQuoteOfTheDay() async {
        await loadQuote(using: .daily, updateContext: false)
    }

    private func loadRandomQuote() async {
        await loadQuote(using: .random, updateContext: false)
    }

    private func loadQuote(using mode: WidgetMode, updateContext: Bool) async {
        state.isLoading = true
        state.errorMessage = nil
        if updateContext {
            state.currentWidgetMode = mode
        }

        do {
            let quote: QuoteRecord
            switch mode {
            case .daily:
                quote = try await quoteProvider.quoteOfTheDay(for: state.currentScript)
            case .random:
                quote = try await quoteProvider.randomQuote(for: state.currentScript)
            }
            updateState(with: quote)
            state.isLoading = false
        } catch {
            state.errorMessage = error.localizedDescription
            state.isLoading = false
        }
    }

    private func updateScript(_ script: RunicScript) async {
        applyScriptPreference(script)
        persistPreferences()

        // Reload quote with new script
        await loadQuote(using: state.currentWidgetMode, updateContext: false)
    }

    private func updateFont(_ font: RunicFont) async {
        // Verify compatibility
        guard font.isCompatible(with: state.currentScript) else {
            state.errorMessage = "\(font.displayName) is not compatible with \(state.currentScript.displayName)"
            return
        }

        // Update preferences
        preferences?.selectedFont = font
        persistPreferences()

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

        state.currentQuoteID = quote.id
        syncSavedStateForCurrentQuote()
    }

    private func applyScriptPreference(_ script: RunicScript) {
        preferences?.selectedScript = script
        state.currentScript = script

        if !state.currentFont.isCompatible(with: script) {
            let recommendedFont = RunicFontConfiguration.recommendedFont(for: script)
            state.currentFont = recommendedFont
            preferences?.selectedFont = recommendedFont
        }
    }

    private func toggleSavedState(for quoteID: UUID) {
        guard let preferences else { return }

        state.isCurrentQuoteSaved = preferences.toggleSavedQuote(quoteID)
        persistPreferences()
    }

    private func syncSavedStateForCurrentQuote() {
        guard let quoteID = state.currentQuoteID else {
            state.isCurrentQuoteSaved = false
            return
        }

        state.isCurrentQuoteSaved = preferences?.isQuoteSaved(quoteID) ?? false
    }

    private func persistPreferences() {
        do {
            try modelContext.save()
        } catch {
            state.errorMessage = "Failed to save preferences: \(error.localizedDescription)"
        }
    }

    private func parseScript(from rawValue: String?) -> RunicScript? {
        guard let rawValue else { return nil }
        let normalized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)

        if let script = RunicScript(rawValue: normalized) {
            return script
        }

        return RunicScript.allCases.first {
            $0.rawValue.caseInsensitiveCompare(normalized) == .orderedSame
        }
    }

    private func parseMode(from rawValue: String?) -> WidgetMode? {
        guard let rawValue else { return nil }
        let normalized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)

        if let mode = WidgetMode(rawValue: normalized) {
            return mode
        }

        return WidgetMode.allCases.first {
            $0.rawValue.caseInsensitiveCompare(normalized) == .orderedSame
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
