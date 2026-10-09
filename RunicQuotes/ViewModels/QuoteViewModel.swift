//
//  QuoteViewModel.swift
//  RunicQuotes
//
//  Created by Claude on 07.10.25.
//

import Combine
import Foundation
import SwiftData
import SwiftUI

/// UI state for the quote view
struct QuoteUiState {
    var runicText: String = ""
    var runicWarnings: [String] = []
    var isRunicRenderingAvailable = true
    var savedTranslationArtifact: TranslationResult?
    var runicPresentationSource: RunicPresentationSource = .storedTransliteration
    var runicEvidenceTier: TranslationEvidenceTier?
    var runicPrimarySourceLabel: String?
    var latinText: String = ""
    var author: String = ""
    var quoteSource: String?
    var currentQuoteID: UUID?
    var isCurrentQuoteSaved: Bool = false
    var currentScript: RunicScript = .elder
    var currentFont: RunicFont = .noto
    var currentReadingMode: WidgetMode = .daily
    var currentCollection: QuoteCollection = .all
    var currentTheme: AppTheme = .obsidian
    var collectionCovers: [QuoteCollectionCover] = QuoteCollection.allCases.map {
        QuoteCollectionCover.placeholder(for: $0, script: .elder)
    }

    var isLoading: Bool = true
    var errorMessage: String?
}

/// Display data for collection cover cards.
struct QuoteCollectionCover: Identifiable {
    let collection: QuoteCollection
    let quoteCount: Int
    let runicPreview: String
    let latinPreview: String
    let authorPreview: String
    let presentationSource: RunicPresentationSource

    var id: String {
        self.collection.rawValue
    }

    static func placeholder(for collection: QuoteCollection, script: RunicScript) -> QuoteCollectionCover {
        QuoteCollectionCover(
            collection: collection,
            quoteCount: 0,
            runicPreview: RunicTransliterator.transliterate(collection.heroLatinText, to: script).glyphOutput,
            latinPreview: collection.heroLatinText,
            authorPreview: collection.displayName,
            presentationSource: .liveTransliteration,
        )
    }
}

/// Search suggestion item for quote discovery.
struct QuoteSearchResult: Identifiable {
    let quote: QuoteRecord
    var id: UUID {
        self.quote.id
    }

    var latinText: String {
        self.quote.textLatin
    }

    var author: String {
        self.quote.author
    }

    var collection: QuoteCollection {
        self.quote.collection
    }
}

/// ViewModel for the main quote display screen
@MainActor
final class QuoteViewModel: ObservableObject {
    // MARK: - Published State

    @Published private(set) var state = QuoteUiState()

    // MARK: - Dependencies

    private let quoteProvider: any QuoteReading
    let translationProvider: any QuoteTranslationReading
    private let preferencesRepository: any UserPreferencesRepository
    private var preferences = UserPreferencesSnapshot()
    private var currentQuoteRecordCache: QuoteRecord?
    var cachedQuotes: [QuoteRecord] = []
    private var acceptsPassiveLoads = true
    private var desiredSelection: Selection = .daily
    private var desiredMode: WidgetMode = .daily
    private var loadGeneration = 0
    private var loadTask: Task<Void, Never>?
    private var presentationScriptOverride: RunicScript?
    private var presentationCollectionOverride: QuoteCollection?

    // MARK: - Initialization

    init(
        quoteProvider: any QuoteReading,
        translationProvider: any QuoteTranslationReading,
        preferencesRepository: any UserPreferencesRepository,
    ) {
        self.quoteProvider = quoteProvider
        self.translationProvider = translationProvider
        self.preferencesRepository = preferencesRepository
    }

    // MARK: - Public API

    func onAppear() {
        self.acceptsPassiveLoads = true
        self.beginLoad(selection: self.desiredSelection)
    }

    func onDisappear() {
        self.acceptsPassiveLoads = false
        self.loadGeneration += 1
        self.loadTask?.cancel()
        self.loadTask = nil
    }

    func onNextQuoteTapped() {
        self.beginLoad(selection: .random, mode: .random)
    }

    func onToggleSaveTapped() {
        guard let id = self.state.currentQuoteID, self.persistPreferences([.toggleSavedQuote(id)]) else { return }
        self.beginLoad(selection: .retain(id))
    }

    func onScriptChanged(_ script: RunicScript) {
        guard self.persistPreferences([.script(script)]) else { return }
        self.presentationScriptOverride = nil
        self.beginLoad(selection: self.retainedSelection)
    }

    func onFontChanged(_ font: RunicFont) {
        let mutations: [UserPreferencesMutation] = self.presentationScriptOverride.map { [.script($0), .font(font)] } ?? [.font(font)]
        guard self.persistPreferences(mutations) else { return }
        self.presentationScriptOverride = nil
        self.beginLoad(selection: self.retainedSelection)
    }

    func onCollectionChanged(_ collection: QuoteCollection) {
        guard self.persistPreferences([.collection(collection)]) else { return }
        self.presentationCollectionOverride = nil
        self.beginLoad(selection: self.selection(for: self.desiredMode))
    }

    func onQuoteSaved(_ id: UUID) {
        self.beginLoad(selection: .focus(id))
    }

    func refresh() {
        self.beginLoad(selection: .daily, mode: .daily)
    }

    func searchResults(for query: String) -> [QuoteSearchResult] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        return self.quotes(for: self.state.currentCollection, within: self.cachedQuotes)
            .filter { $0.textLatin.localizedStandardContains(query) || $0.author.localizedStandardContains(query) }
            .prefix(8)
            .map { QuoteSearchResult(quote: $0) }
    }

    func showQuote(withID id: UUID) {
        self.beginLoad(selection: .focus(id))
    }

    func onPreferencesChanged() {
        guard self.acceptsPassiveLoads else { return }
        self.beginLoad(selection: self.retainedSelection)
    }

    func onLibraryChanged() {
        guard self.acceptsPassiveLoads else { return }
        self.beginLoad(selection: self.retainedSelection)
    }

    func onOpenQuoteDeepLink(quoteID: UUID?, scriptRaw: String?, modeRaw: String?, collectionRaw: String?) {
        self.presentationScriptOverride = self.parseScript(from: scriptRaw)
        self.presentationCollectionOverride = collectionRaw.flatMap(QuoteCollection.init(rawValue:))
        let mode = self.parseMode(from: modeRaw) ?? .daily
        self.beginLoad(selection: quoteID.map(Selection.focus) ?? self.selection(for: mode), mode: mode)
    }

    func currentQuoteRecord() -> QuoteRecord? {
        self.currentQuoteRecordCache
    }

    func hideCurrentQuote() {
        self.archiveCurrentQuote(deleting: false)
    }

    func deleteCurrentQuote() {
        self.archiveCurrentQuote(deleting: true)
    }

    // MARK: - Loading

    private enum Selection {
        case daily
        case random
        case retain(UUID)
        case focus(UUID)
    }

    private var retainedSelection: Selection {
        self.desiredSelection
    }

    private func selection(for mode: WidgetMode) -> Selection {
        mode == .daily ? .daily : .random
    }

    private func beginLoad(selection: Selection, mode: WidgetMode? = nil) {
        self.desiredSelection = selection
        if let mode {
            self.desiredMode = mode
        }
        self.loadGeneration += 1
        let generation = self.loadGeneration
        self.loadTask?.cancel()
        do {
            var preferences = try self.preferencesRepository.snapshot()
            if let collection = self.presentationCollectionOverride {
                preferences.selectedCollection = collection
            }
            let mode = self.desiredMode
            let script = self.presentationScriptOverride ?? preferences.selectedScript
            self.state.isLoading = true
            self.state.errorMessage = nil
            self.loadTask = Task {
                await self.load(selection: selection, mode: mode, script: script, preferences: preferences, generation: generation)
            }
        } catch {
            self.state.isLoading = false
            self.state.errorMessage = error.localizedDescription
        }
    }

    private func load(selection: Selection, mode: WidgetMode, script: RunicScript, preferences: UserPreferencesSnapshot, generation: Int) async {
        var fetchedQuotes: [QuoteRecord]?
        do {
            let allQuotes = try await self.quoteProvider.allQuotes()
            fetchedQuotes = allQuotes
            try Task.checkCancellation()
            var next = self.state
            next.currentScript = script
            next.currentFont = preferences.selectedFont.isCompatible(with: script) ? preferences.selectedFont : RunicFontConfiguration.recommendedFont(for: script)
            next.currentTheme = preferences.selectedTheme
            next.currentCollection = preferences.selectedCollection
            next.currentReadingMode = mode
            let quote = try self.selectedQuote(selection, allQuotes: allQuotes, collection: &next.currentCollection, mode: mode)
            let presentation = await self.preferredRunicPresentation(for: quote, script: next.currentScript)
            try Task.checkCancellation()
            guard generation == self.loadGeneration, !Task.isCancelled else { return }
            if next.currentCollection != preferences.selectedCollection {
                self.presentationCollectionOverride = next.currentCollection
            }
            self.desiredSelection = .retain(quote.id)
            self.preferences = preferences
            self.cachedQuotes = allQuotes
            self.currentQuoteRecordCache = quote
            self.state = self.completedState(next, quote: quote, presentation: presentation, preferences: preferences, allQuotes: allQuotes)
        } catch is CancellationError {
            // The replacement request owns loading state.
        } catch {
            guard generation == self.loadGeneration else { return }
            var next = self.state
            next.isLoading = false
            next.errorMessage = error.localizedDescription
            if let error = error as? QuoteViewModelError, case .emptyCollection = error {
                next.currentScript = script
                next.currentFont = preferences.selectedFont.isCompatible(with: script) ? preferences.selectedFont : RunicFontConfiguration.recommendedFont(for: script)
                next.currentReadingMode = mode
                next.isRunicRenderingAvailable = true
                next.runicPresentationSource = .storedTransliteration
                self.cachedQuotes = fetchedQuotes ?? []
                next.collectionCovers = self.collectionCovers(using: self.cachedQuotes, script: script)
                next.currentCollection = preferences.selectedCollection
                next.currentTheme = preferences.selectedTheme
                next.currentQuoteID = nil
                next.latinText = ""
                next.runicText = ""
                next.runicWarnings = []
                next.runicEvidenceTier = nil
                next.runicPrimarySourceLabel = nil
                next.savedTranslationArtifact = nil
                next.author = ""
                next.quoteSource = nil
                next.isCurrentQuoteSaved = false
                self.currentQuoteRecordCache = nil
            }
            self.state = next
        }
    }

    private func completedState(_ previous: QuoteUiState, quote: QuoteRecord, presentation: ResolvedRunicPresentation, preferences: UserPreferencesSnapshot, allQuotes: [QuoteRecord]) -> QuoteUiState {
        var next = previous
        next.latinText = quote.textLatin
        next.author = quote.author
        next.quoteSource = quote.source
        next.runicText = presentation.text
        next.runicWarnings = presentation.warnings
        next.isRunicRenderingAvailable = presentation.isRenderable
        next.savedTranslationArtifact = presentation.savedArtifact
        next.runicPresentationSource = presentation.source
        next.runicEvidenceTier = presentation.evidenceTier
        next.runicPrimarySourceLabel = presentation.primarySourceLabel
        next.currentQuoteID = quote.id
        next.isCurrentQuoteSaved = preferences.isQuoteSaved(quote.id)
        next.collectionCovers = self.collectionCovers(using: allQuotes, script: next.currentScript)
        next.errorMessage = nil
        next.isLoading = false
        return next
    }

    private func archiveCurrentQuote(deleting: Bool) {
        guard let id = self.state.currentQuoteID else { return }
        Task {
            do {
                if deleting {
                    _ = try await self.quoteProvider.softDeleteQuote(id: id, deletedAt: Date())
                } else {
                    _ = try await self.quoteProvider.hideQuote(id: id)
                }
                if self.state.currentQuoteID == id {
                    self.onNextQuoteTapped()
                } else {
                    self.onLibraryChanged()
                }
            } catch { self.state.errorMessage = error.localizedDescription }
        }
    }

    private func persistPreferences(_ mutations: [UserPreferencesMutation]) -> Bool {
        do {
            self.preferences = try self.preferencesRepository.apply(mutations)
            return true
        } catch {
            self.loadGeneration += 1
            self.loadTask?.cancel()
            self.state.isLoading = false
            self.state.errorMessage = "Failed to save preferences: \(error.localizedDescription)"
            return false
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

    private func collectionCovers(using allQuotes: [QuoteRecord], script: RunicScript) -> [QuoteCollectionCover] {
        QuoteCollection.allCases.map { collection in
            let collectionQuotes = self.quotes(for: collection, within: allQuotes)

            guard let firstQuote = collectionQuotes.first else {
                return QuoteCollectionCover.placeholder(for: collection, script: script)
            }

            let presentation = RunicPresentationResolver.resolve(RunicPresentationInput(quote: firstQuote, script: script), currentCache: nil)
            let runicPreview = presentation.isRenderable ? presentation.text : ""

            return QuoteCollectionCover(
                collection: collection,
                quoteCount: collectionQuotes.count,
                runicPreview: runicPreview,
                latinPreview: firstQuote.textLatin,
                authorPreview: firstQuote.author,
                presentationSource: presentation.source,
            )
        }
    }

}

private extension QuoteViewModel {
    private func selectedQuote(_ selection: Selection, allQuotes: [QuoteRecord], collection: inout QuoteCollection, mode: WidgetMode) throws -> QuoteRecord {
        let filtered = self.quotes(for: collection, within: allQuotes)
        switch selection {
        case .focus(let id):
            guard let quote = allQuotes.first(where: { $0.id == id }) else { throw QuoteRepositoryError.quoteNotFound }
            if !collection.contains(quote) {
                collection = quote.collection
            }
            return quote
        case .retain(let id):
            return try filtered.first(where: { $0.id == id }) ?? self.selectNonemptyQuote(from: filtered, mode: mode, collection: collection)
        case .daily:
            return try self.selectNonemptyQuote(from: filtered, mode: .daily, collection: collection)
        case .random:
            return try self.selectNonemptyQuote(from: filtered, mode: .random, collection: collection)
        }
    }

    private func selectNonemptyQuote(from quotes: [QuoteRecord], mode: WidgetMode, collection: QuoteCollection) throws -> QuoteRecord {
        guard !quotes.isEmpty else { throw QuoteViewModelError.emptyCollection(collection) }
        return self.selectQuote(from: quotes, mode: mode)
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
        return QuoteViewModel(
            quoteProvider: QuoteProvider(modelContainer: container),
            translationProvider: TranslationProvider(modelContainer: container),
            preferencesRepository: preferencesRepository,
        )
    }
}
