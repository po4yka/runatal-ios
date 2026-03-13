//
//  TranslationRepositoryTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftData
import Testing
@testable import RunicQuotes

@Suite(.serialized, .tags(.repository))
struct TranslationRepositoryTests {
    @Test
    func cacheAndLatestTranslationRoundTrip() throws {
        let context = try TestSupport.makeModelContext()
        let quoteRepository = SwiftDataQuoteRepository(modelContext: context)
        let translationRepository = SwiftDataTranslationRepository(modelContext: context)

        let quote = try quoteRepository.createQuote(
            textLatin: "The wolf hunts at night",
            author: "Runatal",
            source: nil,
            collection: .motivation,
            storedRunic: nil
        )
        let result = HistoricalTranslationService().translate(
            text: quote.textLatin,
            script: .younger,
            fidelity: .strict,
            youngerVariant: .longBranch
        )

        try translationRepository.cache(result: result, for: quote.id, sourceText: quote.textLatin)
        let cached = try #require(try translationRepository.latestTranslation(for: quote.id, script: .younger))

        #expect(cached.glyphOutput == result.glyphOutput)
        #expect(cached.engineVersion == result.engineVersion)
        #expect(cached.datasetVersion == result.datasetVersion)
        #expect(cached.evidenceTier == result.evidenceTier)
        #expect(cached.supportLevel == result.supportLevel)
    }

    @Test
    func deleteTranslationsRemovesCachedEntries() throws {
        let context = try TestSupport.makeModelContext()
        let quoteRepository = SwiftDataQuoteRepository(modelContext: context)
        let translationRepository = SwiftDataTranslationRepository(modelContext: context)

        let quote = try quoteRepository.createQuote(
            textLatin: "The wolf hunts at night",
            author: "Runatal",
            source: nil,
            collection: .motivation,
            storedRunic: nil
        )
        let result = HistoricalTranslationService().translate(
            text: quote.textLatin,
            script: .elder,
            fidelity: .strict
        )

        try translationRepository.cache(result: result, for: quote.id, sourceText: quote.textLatin)
        #expect(try translationRepository.latestTranslation(for: quote.id, script: .elder) != nil)

        try translationRepository.deleteTranslations(for: quote.id)

        #expect(try translationRepository.latestTranslation(for: quote.id, script: .elder) == nil)
    }
}
