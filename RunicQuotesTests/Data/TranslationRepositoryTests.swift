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

    @Test
    func corruptedPayloadRegeneratesFromQuoteWithoutLosingExactStoredOutput() throws {
        let context = try TestSupport.makeModelContext()
        let quotes = SwiftDataQuoteRepository(modelContext: context)
        let text = "The wolf hunts at night"
        let record = try quotes.createQuote(
            textLatin: text, author: "Audit", source: nil, collection: .stoic,
            storedRunic: RunicTextBundle(elder: nil, younger: "USER-EXACT-OUTPUT", cirth: nil),
        )
        let translations = SwiftDataTranslationRepository(modelContext: context)
        let result = HistoricalTranslationService().translate(text: text, script: .younger, fidelity: .strict)
        try translations.cache(result: result, for: record.id, sourceText: text)
        let damageContext = ModelContext(context.container)
        let payload = try #require(damageContext.fetch(FetchDescriptor<TranslationRecord>()).first)
        payload.provenanceData = Data("invalid-json".utf8)
        try damageContext.save()
        let regenerated = try #require(translations.latestTranslation(for: record.id, script: .younger))
        #expect(regenerated.glyphOutput == result.glyphOutput)
        #expect(!regenerated.provenance.isEmpty)
        #expect(try quotes.quote(id: record.id)?.runicYounger == "USER-EXACT-OUTPUT")
        #expect(try ModelContext(context.container).fetchCount(FetchDescriptor<TranslationRecord>()) == 1)
    }

    @Test
    func invalidResultMetadataCannotPartiallySaveStructuredQuote() throws {
        let context = try TestSupport.makeModelContext()
        let quotes = SwiftDataQuoteRepository(modelContext: context)
        let invalid = TestSupport.makeTranslationResult(confidence: .nan)
        #expect(throws: TranslationRecordError.self) {
            try quotes.createQuote(textLatin: invalid.sourceText, author: "Audit", source: nil, collection: .stoic, translations: [invalid])
        }
        let persisted = ModelContext(context.container)
        #expect(try persisted.fetchCount(FetchDescriptor<Quote>()) == 0)
        #expect(try persisted.fetchCount(FetchDescriptor<TranslationRecord>()) == 0)
    }

}
