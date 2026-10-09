//
//  TranslationCacheFreshnessTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
@testable import RunicQuotes
import SwiftData
import Testing

@MainActor
@Suite(.serialized, .tags(.repository))
struct TranslationCacheFreshnessTests {
    @Test
    func cacheLookupRequiresCurrentEngineDatasetAndQuoteSource() throws {
        let context = try TestSupport.makeModelContext()
        let quotes = SwiftDataQuoteRepository(modelContext: context)
        let text = "The wolf hunts at night"
        let quote = try quotes.createQuote(textLatin: text, author: "Audit", source: nil, collection: .stoic)
        let service = HistoricalTranslationService()
        let current = service.translate(text: text, script: .younger, fidelity: .strict)
        let translations = SwiftDataTranslationRepository(modelContext: context, translationService: service)
        let oldEngine = TestSupport.makeTranslationResult(sourceText: text, engineVersion: "obsolete-engine", datasetVersion: current.datasetVersion)
        try translations.cache(result: oldEngine, for: quote.id, sourceText: text)
        #expect(try translations.latestTranslation(for: quote.id, script: .younger) == nil)
        let oldDataset = TestSupport.makeTranslationResult(sourceText: text, engineVersion: current.engineVersion, datasetVersion: "obsolete-dataset")
        try translations.cache(result: oldDataset, for: quote.id, sourceText: text)
        #expect(try translations.latestTranslation(for: quote.id, script: .younger) == nil)
        try translations.cache(result: current, for: quote.id, sourceText: text)
        #expect(try translations.latestTranslation(for: quote.id, script: .younger)?.sourceText == text)
        let editedContext = ModelContext(context.container)
        let model = try #require(editedContext.fetch(FetchDescriptor<Quote>()).first)
        model.textLatin = "Changed source"
        try editedContext.save()
        #expect(try translations.latestTranslation(for: quote.id, script: .younger) == nil)
        #expect(throws: TranslationCacheError.self) { try translations.cache(result: current, for: quote.id, sourceText: text) }
        #expect(throws: QuoteRepositoryError.self) { try translations.cache(result: current, for: UUID(), sourceText: text) }
    }

    @Test
    func currentUnavailableResultSupersedesObsoleteSupportWithoutOverwritingSavedArtifact() async throws {
        let context = try TestSupport.makeModelContext()
        let quotes = SwiftDataQuoteRepository(modelContext: context)
        let text = "волк ночью"
        let old = TestSupport.makeTranslationResult(sourceText: text, engineVersion: "obsolete-engine", datasetVersion: "obsolete-dataset")
        let quote = try quotes.createQuote(
            textLatin: text, author: "Audit", source: nil, collection: .stoic,
            storedRunic: RunicTextBundle(elder: nil, younger: "USER-SAVED-EXACT", cirth: nil), translations: [old],
        )
        let translations = SwiftDataTranslationRepository(modelContext: context)
        try await translations.backfillAllQuotes()
        let latest = try #require(try translations.latestTranslation(for: quote.id, script: .younger))
        #expect(latest.resolutionStatus == .unavailable)
        #expect(!latest.isAvailable)
        let preserved = try #require(try quotes.quote(id: quote.id))
        #expect(preserved.runicYounger == "USER-SAVED-EXACT")
        let metadata = try #require(preserved.storedTranslationMetadataData)
        let artifact = try JSONDecoder().decode([TranslationResult].self, from: metadata)
        #expect(artifact.first?.engineVersion == old.engineVersion)
        #expect(artifact.first?.sourceText == text)
    }
}
