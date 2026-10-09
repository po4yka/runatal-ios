//
//  WidgetLibraryService.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
import SwiftData

final class WidgetLibraryService: WidgetTimelineServicing, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func loadPreferences() throws -> UserPreferencesSnapshot {
        try self.makePreferencesRepository().snapshot()
    }

    func quoteOfTheDay(for script: RunicScript, collection: QuoteCollection, date: Date = Date()) async throws -> QuoteData {
        let provider = self.makeQuoteProvider()
        try await provider.seedIfNeeded()

        let allQuotes = try await provider.allQuotes().filter(collection.contains)
        guard !allQuotes.isEmpty else {
            throw QuoteRepositoryError.noQuotesAvailable
        }

        let index = AppConstants.dailyQuoteIndex(for: date, totalQuotes: allQuotes.count)
        return try await self.presentationData(for: allQuotes[index], script: script)
    }

    func randomQuote(for script: RunicScript, collection: QuoteCollection) async throws -> QuoteData {
        let provider = self.makeQuoteProvider()
        try await provider.seedIfNeeded()
        let quotes = try await provider.allQuotes().filter(collection.contains)
        guard let quote = quotes.randomElement() else { throw QuoteRepositoryError.noQuotesAvailable }
        return try await self.presentationData(for: quote, script: script)
    }

    private func presentationData(for quote: QuoteRecord, script: RunicScript) async throws -> QuoteData {
        let cache = try await TranslationProvider(modelContainer: self.modelContainer).latestTranslation(for: quote.id, script: script)
        var presentation = RunicPresentationResolver.resolve(RunicPresentationInput(quote: quote, script: script), currentCache: cache)
        // The widget needs the result/disclosure rather than the full token/provenance artifact payload.
        presentation.savedArtifact = nil
        return QuoteData(from: quote, presentation: presentation, script: script)
    }

    private func makeQuoteProvider() -> QuoteProvider {
        QuoteProvider(modelContainer: self.modelContainer)
    }

    private func makePreferencesRepository() -> SwiftDataUserPreferencesRepository {
        SwiftDataUserPreferencesRepository(modelContext: ModelContext(self.modelContainer))
    }
}
