//
//  TranslationBatchLookupTests.swift
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
struct TranslationBatchLookupTests {
    @Test
    func batchedLookupHonorsCurrentSourceVersionsAndPermanentSavedArtifacts() throws {
        let context = try TestSupport.makeModelContext()
        let quotes = SwiftDataQuoteRepository(modelContext: context)
        let service = HistoricalTranslationService()
        let translations = SwiftDataTranslationRepository(modelContext: context)
        let first = try quotes.createQuote(textLatin: "The wolf hunts at night", author: "Reader", source: nil, collection: .stoic)
        let second = try quotes.createQuote(textLatin: "computer", author: "Reader", source: nil, collection: .stoic)
        let firstResult = service.translate(text: first.textLatin, script: .younger, fidelity: .strict)
        let secondResult = service.translate(text: second.textLatin, script: .younger, fidelity: .readable)
        try translations.cache(result: firstResult, for: first.id, sourceText: first.textLatin)
        try translations.cache(result: secondResult, for: second.id, sourceText: second.textLatin)
        let batch = try translations.latestTranslations(for: [first.id, second.id], script: .younger)
        #expect(batch.count == 2)
        #expect(batch[first.id]?.glyphOutput == firstResult.glyphOutput)
        #expect(batch[second.id]?.glyphOutput == secondResult.glyphOutput)
        let editContext = ModelContext(context.container)
        let id = first.id
        let original = try #require(editContext.fetch(FetchDescriptor<Quote>(predicate: #Predicate { $0.id == id })).first)
        original.textLatin = "An edited passage"
        try editContext.save()
        let refreshed = try translations.latestTranslations(for: [first.id, second.id], script: .younger)
        #expect(refreshed[first.id] == nil)
        #expect(refreshed[second.id]?.sourceText == second.textLatin)
        #expect(try translations.latestTranslation(for: second.id, script: .younger)?.glyphOutput == refreshed[second.id]?.glyphOutput)
    }
}
