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
    var currentCollection: QuoteCollection = .all
    var currentTheme: AppTheme = .obsidian
    var collectionCovers: [QuoteCollectionCover] = QuoteCollection.allCases.map {
        QuoteCollectionCover.placeholder(for: $0)
    }
    var isLoading: Bool = true
    var errorMessage: String?
}

/// Display data for collection cover cards.
struct QuoteCollectionCover: Identifiable, Sendable {
    let collection: QuoteCollection
    let quoteCount: Int
    let runicPreview: String
    let latinPreview: String
    let authorPreview: String

    var id: String { collection.rawValue }

    static func placeholder(for collection: QuoteCollection) -> QuoteCollectionCover {
        QuoteCollectionCover(
            collection: collection,
            quoteCount: 0,
            runicPreview: collection.heroRunicText,
            latinPreview: collection.heroLatinText,
            authorPreview: collection.displayName
        )
    }
}

/// Search suggestion item for quote discovery.
struct QuoteSearchResult: Identifiable, Sendable {
    let id: UUID
    let latinText: String
    let author: String
    let collection: QuoteCollection
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
    private var cachedQuotes: [QuoteRecord] = []

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

    /// Change the current quote collection.
    func onCollectionChanged(_ collection: QuoteCollection) {
        guard state.currentCollection != collection else { return }

        preferences?.selectedCollection = collection
        state.currentCollection = collection
        persistPreferences()

        Task {
            await loadQuote(using: state.currentWidgetMode, updateContext: false)
        }
    }

    /// Refresh the quote of the day
    func refresh() {
        Task {
            await loadQuoteOfTheDay()
        }
    }

    /// Search cached quotes by author or content and return compact suggestions.
    func searchResults(for query: String) -> [QuoteSearchResult] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else { return [] }

        let searchScope = quotes(for: state.currentCollection, within: cachedQuotes)
        return searchScope
            .filter {
                $0.textLatin.localizedCaseInsensitiveContains(normalizedQuery) ||
                    $0.author.localizedCaseInsensitiveContains(normalizedQuery)
            }
            .prefix(8)
            .map {
                QuoteSearchResult(
                    id: $0.id,
                    latinText: $0.textLatin,
                    author: $0.author,
                    collection: $0.collection
                )
            }
    }

    /// Display a specific quote selected from search suggestions.
    func showQuote(withID quoteID: UUID) {
        guard let match = cachedQuotes.first(where: { $0.id == quoteID }) else { return }
        updateState(with: match)
    }

    /// Apply updated persisted preferences (e.g. after changes in Settings tab).
    func onPreferencesChanged() {
        Task {
            let previousScript = state.currentScript
            let previousMode = state.currentWidgetMode
            let previousCollection = state.currentCollection
            await loadPreferences()

            if previousScript != state.currentScript ||
                previousMode != state.currentWidgetMode ||
                previousCollection != state.currentCollection {
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
            state.currentCollection = preferences?.selectedCollection ?? .all
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
            let allQuotes = try await quoteProvider.allQuotes()
            cachedQuotes = allQuotes
            updateCollectionCovers(using: allQuotes)

            let filteredQuotes = quotes(for: state.currentCollection, within: allQuotes)
            guard !filteredQuotes.isEmpty else {
                throw QuoteViewModelError.emptyCollection(state.currentCollection)
            }

            let quote = selectQuote(from: filteredQuotes, mode: mode)
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

    private func quotes(for collection: QuoteCollection, within allQuotes: [QuoteRecord]) -> [QuoteRecord] {
        if collection == .all {
            return allQuotes
        }

        return allQuotes.filter(collection.contains)
    }

    private func selectQuote(from quotes: [QuoteRecord], mode: WidgetMode) -> QuoteRecord {
        switch mode {
        case .daily:
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let daysSinceEpoch = calendar.dateComponents(
                [.day],
                from: Date(timeIntervalSince1970: 0),
                to: today
            ).day ?? 0

            let index = daysSinceEpoch % quotes.count
            return quotes[index]
        case .random:
            let randomIndex = Int.random(in: 0..<quotes.count)
            return quotes[randomIndex]
        }
    }

    private func updateCollectionCovers(using allQuotes: [QuoteRecord]) {
        state.collectionCovers = QuoteCollection.allCases.map { collection in
            let collectionQuotes = quotes(for: collection, within: allQuotes)

            guard let firstQuote = collectionQuotes.first else {
                return QuoteCollectionCover.placeholder(for: collection)
            }

            let runicPreview = firstQuote.runicText(for: state.currentScript)
                ?? RunicTransliterator.transliterate(firstQuote.textLatin, to: state.currentScript)

            return QuoteCollectionCover(
                collection: collection,
                quoteCount: collectionQuotes.count,
                runicPreview: runicPreview,
                latinPreview: firstQuote.textLatin,
                authorPreview: firstQuote.author
            )
        }
    }
}

enum QuoteViewModelError: LocalizedError {
    case emptyCollection(QuoteCollection)

    var errorDescription: String? {
        switch self {
        case .emptyCollection(let collection):
            return "No quotes available in the \(collection.displayName) collection."
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
