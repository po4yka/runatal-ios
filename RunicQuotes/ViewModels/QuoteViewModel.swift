//
//  QuoteViewModel.swift
//  RunicQuotes
//
//  Created by Claude on 07.10.25.
//

import Foundation
import SwiftData
import SwiftUI

// swiftlint:disable file_length

/// UI state for the quote view
struct QuoteUiState {
    var runicText: String = ""
    var runicPresentationSource: RunicPresentationSource = .storedTransliteration
    var runicEvidenceTier: TranslationEvidenceTier?
    var runicPrimarySourceLabel: String?
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

enum RunicPresentationSource: String {
    case structuredTranslation
    case storedTransliteration
    case liveTransliteration

    var disclosureTitle: String {
        switch self {
        case .structuredTranslation:
            "Structured historical translation"
        case .storedTransliteration:
            "Stored transliteration"
        case .liveTransliteration:
            "On-demand transliteration"
        }
    }

    var shareDisclosureTitle: String {
        switch self {
        case .structuredTranslation:
            "Historical translation"
        case .storedTransliteration:
            "Stored transliteration"
        case .liveTransliteration:
            "Transliteration fallback"
        }
    }
}

/// Display data for collection cover cards.
struct QuoteCollectionCover: Identifiable {
    let collection: QuoteCollection
    let quoteCount: Int
    let runicPreview: String
    let latinPreview: String
    let authorPreview: String

    var id: String {
        self.collection.rawValue
    }

    static func placeholder(for collection: QuoteCollection) -> QuoteCollectionCover {
        QuoteCollectionCover(
            collection: collection,
            quoteCount: 0,
            runicPreview: collection.heroRunicText,
            latinPreview: collection.heroLatinText,
            authorPreview: collection.displayName,
        )
    }
}

/// Search suggestion item for quote discovery.
struct QuoteSearchResult: Identifiable {
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

    private let quoteProvider: QuoteProvider
    let translationProvider: TranslationProvider
    private let preferencesRepository: any UserPreferencesRepository
    private var preferences = UserPreferencesSnapshot()
    private var currentQuoteRecordCache: QuoteRecord?
    var cachedQuotes: [QuoteRecord] = []

    // MARK: - Initialization

    init(
        quoteProvider: QuoteProvider,
        translationProvider: TranslationProvider,
        preferencesRepository: any UserPreferencesRepository,
    ) {
        self.quoteProvider = quoteProvider
        self.translationProvider = translationProvider
        self.preferencesRepository = preferencesRepository
    }

    // MARK: - Public API

    /// Load initial quote when view appears
    func onAppear() {
        Task {
            await self.loadPreferences()
            await self.loadQuoteOfTheDay()
        }
    }

    /// Load the next random quote
    func onNextQuoteTapped() {
        self.state.isLoading = true
        Task {
            await self.loadRandomQuote()
        }
    }

    /// Toggle save state for the currently visible quote.
    func onToggleSaveTapped() {
        guard let quoteID = state.currentQuoteID else { return }
        self.toggleSavedState(for: quoteID)
    }

    /// Change the current runic script
    func onScriptChanged(_ script: RunicScript) {
        self.state.isLoading = true
        Task {
            await self.updateScript(script)
        }
    }

    /// Change the current font
    func onFontChanged(_ font: RunicFont) {
        Task {
            await self.updateFont(font)
        }
    }

    /// Change the current quote collection.
    func onCollectionChanged(_ collection: QuoteCollection) {
        guard self.state.currentCollection != collection else { return }

        self.preferences.selectedCollection = collection
        self.state.currentCollection = collection
        self.persistPreferences()
        self.state.isLoading = true

        Task {
            await self.loadQuote(using: self.state.currentWidgetMode, updateContext: false)
        }
    }

    /// Refresh the quote of the day
    func refresh() {
        self.state.isLoading = true
        Task {
            await self.loadQuoteOfTheDay()
        }
    }

    /// Search cached quotes by author or content and return compact suggestions.
    func searchResults(for query: String) -> [QuoteSearchResult] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else { return [] }

        let searchScope = self.quotes(for: self.state.currentCollection, within: self.cachedQuotes)
        return searchScope
            .filter {
                $0.textLatin.localizedStandardContains(normalizedQuery) ||
                    $0.author.localizedStandardContains(normalizedQuery)
            }
            .prefix(8)
            .map {
                QuoteSearchResult(
                    id: $0.id,
                    latinText: $0.textLatin,
                    author: $0.author,
                    collection: $0.collection,
                )
            }
    }

    /// Display a specific quote selected from search suggestions.
    func showQuote(withID quoteID: UUID) {
        guard let match = cachedQuotes.first(where: { $0.id == quoteID }) else { return }
        Task {
            await self.updateState(with: match)
        }
    }

    /// Apply updated persisted preferences (e.g. after changes in Settings tab).
    func onPreferencesChanged() {
        self.state.isLoading = true
        Task {
            let previousScript = self.state.currentScript
            let previousMode = self.state.currentWidgetMode
            let previousCollection = self.state.currentCollection
            await self.loadPreferences()

            let preferencesChanged =
                previousScript != self.state.currentScript ||
                previousMode != self.state.currentWidgetMode ||
                previousCollection != self.state.currentCollection

            if preferencesChanged {
                await self.loadQuote(using: self.state.currentWidgetMode, updateContext: true)
            }
        }
    }

    func updateDisplayedRunicText(_ runicText: String) {
        self.state.runicText = runicText
    }

    func updateDisplayedRunicPresentation(_ presentation: ResolvedRunicPresentation) {
        self.state.runicText = presentation.text
        self.state.runicPresentationSource = presentation.source
        self.state.runicEvidenceTier = presentation.evidenceTier
        self.state.runicPrimarySourceLabel = presentation.primarySourceLabel
    }

    /// Apply deep-link context from widget and open quote screen in matching state.
    func onOpenQuoteDeepLink(scriptRaw: String?, modeRaw: String?) {
        let script = self.parseScript(from: scriptRaw)
        let mode = self.parseMode(from: modeRaw)
        self.state.isLoading = true

        Task {
            await self.loadPreferences()

            if let script {
                self.applyScriptPreference(script)
            }

            if let mode {
                self.state.currentWidgetMode = mode
                self.preferences.widgetMode = mode
            }

            self.persistPreferences()
            await self.loadQuote(using: mode ?? self.state.currentWidgetMode, updateContext: true)
        }
    }

    // MARK: - Private Methods

    private func loadPreferences() async {
        do {
            self.preferences = try self.preferencesRepository.snapshot()

            // Update state with preferences
            self.state.currentScript = self.preferences.selectedScript
            self.state.currentFont = self.preferences.selectedFont
            self.state.currentWidgetMode = self.preferences.widgetMode
            self.state.currentCollection = self.preferences.selectedCollection
            self.state.currentTheme = self.preferences.selectedTheme
            self.syncSavedStateForCurrentQuote()
        } catch {
            self.state.errorMessage = "Failed to load preferences: \(error.localizedDescription)"
        }
    }

    private func loadQuoteOfTheDay() async {
        await self.loadQuote(using: .daily, updateContext: false)
    }

    private func loadRandomQuote() async {
        await self.loadQuote(using: .random, updateContext: false)
    }

    private func loadQuote(using mode: WidgetMode, updateContext: Bool) async {
        self.state.isLoading = true
        self.state.errorMessage = nil
        if updateContext {
            self.state.currentWidgetMode = mode
        }

        do {
            let allQuotes = try await quoteProvider.allQuotes()
            self.cachedQuotes = allQuotes
            self.updateCollectionCovers(using: allQuotes)

            let filteredQuotes = self.quotes(for: self.state.currentCollection, within: allQuotes)
            guard !filteredQuotes.isEmpty else {
                throw QuoteViewModelError.emptyCollection(self.state.currentCollection)
            }

            let quote = self.selectQuote(from: filteredQuotes, mode: mode)
            await self.updateState(with: quote)
            self.state.isLoading = false
        } catch {
            self.state.errorMessage = error.localizedDescription
            self.state.isLoading = false
        }
    }

    private func updateScript(_ script: RunicScript) async {
        self.applyScriptPreference(script)
        self.persistPreferences()

        // Reload quote with new script
        await self.loadQuote(using: self.state.currentWidgetMode, updateContext: false)
    }

    private func updateFont(_ font: RunicFont) async {
        // Verify compatibility
        guard font.isCompatible(with: self.state.currentScript) else {
            self.state.errorMessage = "\(font.displayName) is not compatible with \(self.state.currentScript.displayName)"
            return
        }

        // Update preferences
        self.preferences.selectedFont = font
        self.persistPreferences()

        // Update state
        self.state.currentFont = font
    }

    private func updateState(with quote: QuoteRecord) async {
        self.currentQuoteRecordCache = quote
        self.state.latinText = quote.textLatin
        self.state.author = quote.author
        let presentation = await preferredRunicPresentation(for: quote)
        self.updateDisplayedRunicPresentation(presentation)

        self.state.currentQuoteID = quote.id
        self.syncSavedStateForCurrentQuote()
    }

    private func applyScriptPreference(_ script: RunicScript) {
        self.preferences.selectedScript = script
        self.state.currentScript = script

        if !self.state.currentFont.isCompatible(with: script) {
            let recommendedFont = RunicFontConfiguration.recommendedFont(for: script)
            self.state.currentFont = recommendedFont
            self.preferences.selectedFont = recommendedFont
        }
    }

    private func toggleSavedState(for quoteID: UUID) {
        self.state.isCurrentQuoteSaved = self.preferences.toggleSavedQuote(quoteID)
        self.persistPreferences()
    }

    private func syncSavedStateForCurrentQuote() {
        guard let quoteID = state.currentQuoteID else {
            self.state.isCurrentQuoteSaved = false
            return
        }

        self.state.isCurrentQuoteSaved = self.preferences.isQuoteSaved(quoteID)
    }

    /// Return the current quote as a `QuoteRecord`, or `nil` if unavailable.
    func currentQuoteRecord() -> QuoteRecord? {
        self.currentQuoteRecordCache
    }

    /// Hide the current quote and advance to the next one.
    func hideCurrentQuote() {
        guard let quoteID = state.currentQuoteID else { return }

        Task {
            do {
                self.currentQuoteRecordCache = try await self.quoteProvider.hideQuote(id: quoteID)
                self.onNextQuoteTapped()
            } catch {
                self.state.errorMessage = error.localizedDescription
            }
        }
    }

    /// Soft-delete the current quote and advance to the next one.
    func deleteCurrentQuote() {
        guard let quoteID = state.currentQuoteID else { return }

        Task {
            do {
                self.currentQuoteRecordCache = try await self.quoteProvider.softDeleteQuote(id: quoteID)
                self.onNextQuoteTapped()
            } catch {
                self.state.errorMessage = error.localizedDescription
            }
        }
    }

    private func persistPreferences() {
        do {
            try self.preferencesRepository.save(self.preferences)
        } catch {
            self.state.errorMessage = "Failed to save preferences: \(error.localizedDescription)"
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
            let index = AppConstants.dailyQuoteIndex(totalQuotes: quotes.count)
            return quotes[index]
        case .random:
            let randomIndex = Int.random(in: 0 ..< quotes.count)
            return quotes[randomIndex]
        }
    }

    func updateCollectionCovers(using allQuotes: [QuoteRecord]) {
        self.state.collectionCovers = QuoteCollection.allCases.map { collection in
            let collectionQuotes = self.quotes(for: collection, within: allQuotes)

            guard let firstQuote = collectionQuotes.first else {
                return QuoteCollectionCover.placeholder(for: collection)
            }

            let runicPreview = firstQuote.runicText(for: self.state.currentScript)
                ?? RunicTransliterator.transliterate(firstQuote.textLatin, to: self.state.currentScript)

            return QuoteCollectionCover(
                collection: collection,
                quoteCount: collectionQuotes.count,
                runicPreview: runicPreview,
                latinPreview: firstQuote.textLatin,
                authorPreview: firstQuote.author,
            )
        }
    }

}

enum QuoteViewModelError: LocalizedError {
    case emptyCollection(QuoteCollection)

    var errorDescription: String? {
        switch self {
        case .emptyCollection(let collection):
            "No quotes available in the \(collection.displayName) collection."
        }
    }
}

// MARK: - Preview Helper

extension QuoteViewModel {
    /// Create a view model for SwiftUI previews
    static func preview() -> QuoteViewModel {
        let container = ModelContainerHelper.createPlaceholderContainer()
        let preferencesRepository = SwiftDataUserPreferencesRepository(modelContext: container.mainContext)
        let translationRepository = SwiftDataTranslationRepository(modelContext: container.mainContext)
        let quoteRepository = SwiftDataQuoteRepository(
            modelContext: container.mainContext,
            translationCacheRepository: translationRepository,
        )
        return QuoteViewModel(
            quoteProvider: QuoteProvider(repository: quoteRepository),
            translationProvider: TranslationProvider(repository: translationRepository),
            preferencesRepository: preferencesRepository,
        )
    }
}
