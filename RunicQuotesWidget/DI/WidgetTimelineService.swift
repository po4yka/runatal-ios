//
//  WidgetTimelineService.swift
//  RunicQuotesWidget
//
//  Created by Codex on 2026-03-13.
//

import Foundation
import SwiftData

final class WidgetTimelineService: WidgetTimelineServicing, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func loadPreferences() throws -> UserPreferencesSnapshot {
        try makePreferencesRepository().snapshot()
    }

    func quoteOfTheDay(for script: RunicScript, date: Date = Date()) async throws -> QuoteData {
        let provider = makeQuoteProvider()
        try await provider.seedIfNeeded()

        let allQuotes = try await provider.allQuotes()
        guard !allQuotes.isEmpty else {
            throw WidgetError.noQuotesAvailable
        }

        let index = AppConstants.dailyQuoteIndex(for: date, totalQuotes: allQuotes.count)
        return QuoteData(from: allQuotes[index])
    }

    func randomQuote(for script: RunicScript) async throws -> QuoteData {
        let provider = makeQuoteProvider()
        try await provider.seedIfNeeded()
        return QuoteData(from: try await provider.randomQuote(for: script))
    }

    private func makeQuoteProvider() -> QuoteProvider {
        let context = ModelContext(modelContainer)
        let translationRepository = SwiftDataTranslationRepository(modelContext: context)
        let quoteRepository = SwiftDataQuoteRepository(
            modelContext: context,
            translationCacheRepository: translationRepository
        )
        return QuoteProvider(repository: quoteRepository)
    }

    private func makePreferencesRepository() -> SwiftDataUserPreferencesRepository {
        SwiftDataUserPreferencesRepository(modelContext: ModelContext(modelContainer))
    }
}
