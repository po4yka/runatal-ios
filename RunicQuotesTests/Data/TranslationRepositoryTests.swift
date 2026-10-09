//
//  TranslationRepositoryTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import Foundation
@testable import RunicQuotes
import SwiftData
import Testing

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
            storedRunic: nil,
        )
        let result = HistoricalTranslationService().translate(
            text: quote.textLatin,
            script: .younger,
            fidelity: .strict,
            youngerVariant: .longBranch,
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
            storedRunic: nil,
        )
        let result = HistoricalTranslationService().translate(
            text: quote.textLatin,
            script: .elder,
            fidelity: .strict,
        )

        try translationRepository.cache(result: result, for: quote.id, sourceText: quote.textLatin)
        #expect(try translationRepository.latestTranslation(for: quote.id, script: .elder) != nil)

        try translationRepository.deleteTranslations(for: quote.id)

        #expect(try translationRepository.latestTranslation(for: quote.id, script: .elder) == nil)
    }

    @Test
    func replacingSameCacheKeyUpdatesDerivationAndHistoricalMetadata() throws {
        let context = try TestSupport.makeModelContext()
        let quotes = SwiftDataQuoteRepository(modelContext: context)
        let record = try quotes.createQuote(textLatin: "The wolf hunts at night", author: "Audit", source: nil, collection: .stoic)
        let translations = SwiftDataTranslationRepository(modelContext: context)
        let first = TestSupport.makeTranslationResult(derivationKind: .goldExample, historicalStage: .oldNorse)
        let second = TestSupport.makeTranslationResult(
            derivationKind: .tokenComposed, historicalStage: .protoNorse,
            glyphOutput: "NEW", notes: ["Changed derivation"], createdAt: Date(timeIntervalSince1970: 42),
        )
        try translations.cache(result: first, for: record.id, sourceText: record.textLatin)
        try translations.cache(result: second, for: record.id, sourceText: record.textLatin)
        let cached = try #require(translations.latestTranslation(for: record.id, script: second.script))
        #expect(cached.derivationKind == second.derivationKind)
        #expect(cached.historicalStage == second.historicalStage)
        #expect(cached.createdAt == second.createdAt)
        #expect(cached.glyphOutput == second.glyphOutput)
        #expect(cached.notes == second.notes)
        #expect(try ModelContext(context.container).fetchCount(FetchDescriptor<TranslationRecord>()) == 1)
    }

}
