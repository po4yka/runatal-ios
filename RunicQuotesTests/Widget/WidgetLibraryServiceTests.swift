//
//  WidgetLibraryServiceTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
@testable import RunicQuotes
import SwiftData
import Testing

@MainActor
@Suite(.serialized, .tags(.widget))
struct WidgetLibraryServiceTests {
    @Test
    func widgetUsesTheSameApprovedHistoricalPresentationAsHome() async throws {
        let context = try TestSupport.makeModelContext()
        let repository = try TestSupport.makeSeededRepository(in: context)
        let quote = try #require(try repository.allQuotes().first { $0.textLatin == "Harja" })
        let cached = HistoricalTranslationService().translate(text: quote.textLatin, script: .elder, fidelity: .strict)
        #expect(cached.isAvailable)
        try SwiftDataTranslationRepository(modelContext: context).cache(result: cached, for: quote.id, sourceText: quote.textLatin)
        for other in try repository.allQuotes() where other.id != quote.id {
            _ = try repository.hideQuote(id: other.id)
        }
        let widget = try await WidgetLibraryService(modelContainer: context.container).quoteOfTheDay(for: .elder, collection: .all, date: Date())
        #expect(widget.runicRendering(for: .elder).text == "ᚺᚨᚱᛃᚨ")
        #expect(widget.runicRendering(for: .elder).source == .structuredTranslation)
        #expect(widget.runicRendering(for: .elder).evidenceTier == .attested)
    }

    @Test
    func dailyAndRandomEntriesUseTheResolvedCollectionInTheRealStore() async throws {
        let context = try TestSupport.makeModelContext()
        let repository = try TestSupport.makeSeededRepository(in: context)
        let service = WidgetLibraryService(modelContainer: context.container)
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let quotes = try repository.allQuotes().filter(QuoteCollection.stoic.contains)
        let ids = Set(quotes.map(\.id))
        let daily = try await service.quoteOfTheDay(for: .elder, collection: .stoic, date: date)
        #expect(daily.id == quotes[AppConstants.dailyQuoteIndex(for: date, totalQuotes: quotes.count)].id)
        for _ in 0 ..< 8 {
            let random = try await service.randomQuote(for: .elder, collection: .stoic)
            #expect(ids.contains(random.id))
        }
    }

    @Test
    func emptySelectedCollectionDoesNotFallBackToOtherVisiblePassages() async throws {
        let context = try TestSupport.makeModelContext()
        let repository = try TestSupport.makeSeededRepository(in: context)
        for quote in try repository.allQuotes().filter(QuoteCollection.stoic.contains) {
            _ = try repository.hideQuote(id: quote.id)
        }
        #expect(try !repository.allQuotes().isEmpty)
        let service = WidgetLibraryService(modelContainer: context.container)
        await #expect(throws: QuoteRepositoryError.self) {
            try await service.quoteOfTheDay(for: .elder, collection: .stoic, date: Date())
        }
        await #expect(throws: QuoteRepositoryError.self) {
            try await service.randomQuote(for: .elder, collection: .stoic)
        }
    }
}
