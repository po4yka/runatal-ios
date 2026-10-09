//
//  QuoteArtifactEditTests.swift
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
struct QuoteArtifactEditTests {
    @Test
    func metadataOnlyEditPreservesExactHistoricalGlyphsAndOriginalAssessment() throws {
        let context = try TestSupport.makeModelContext()
        let repository = SwiftDataQuoteRepository(modelContext: context)
        let result = HistoricalTranslationService().translate(text: "The wolf hunts at night", script: .younger, fidelity: .strict)
        #expect(result.isAvailable)
        #expect(result.glyphOutput != RunicTransliterator.transliterate(result.sourceText, to: .younger).glyphOutput)
        let original = try repository.createQuote(
            textLatin: result.sourceText,
            author: "Reader",
            source: nil,
            collection: .stoic,
            storedRunic: RunicTextBundle(elder: nil, younger: result.glyphOutput, cirth: nil),
            translations: [result],
        )
        let updated = try repository.updateQuote(
            id: original.id,
            textLatin: original.textLatin,
            author: "Corrected author",
            source: "Corrected source",
            collection: .motivation,
            storedRunic: RunicTextBundle(elder: "ᚠ", younger: "ᚢ", cirth: "\u{E080}"),
        )
        #expect(updated.id == original.id)
        #expect(updated.author == "Corrected author")
        #expect(updated.source == "Corrected source")
        #expect(updated.collection == .motivation)
        #expect(updated.runicElder == original.runicElder)
        #expect(updated.runicYounger == result.glyphOutput)
        #expect(updated.runicCirth == original.runicCirth)
        #expect(updated.storedTranslationMetadataData == original.storedTranslationMetadataData)
    }

    @Test
    func editingSourceTextReplacesOldEncodingMarkerWithCurrentCirthEncoding() throws {
        let context = try TestSupport.makeModelContext()
        let quote = Quote(textLatin: "Old text", author: "Reader", collection: .stoic, isUserGenerated: true)
        quote.runicCirth = "\u{E001}"
        quote.cirthEncodingRaw = "CIRTH_UNKNOWN_V0"
        context.insert(quote)
        try context.save()
        let repository = SwiftDataQuoteRepository(modelContext: context)
        let updated = try repository.updateQuote(
            id: quote.id,
            textLatin: "New text",
            author: quote.author,
            source: nil,
            collection: .stoic,
            storedRunic: nil,
        )
        #expect(updated.cirthEncodingRaw == LegacyCirthEncodingMigration.encoding)
        #expect(updated.runicCirth == RunicTransliterator.transliterate(updated.textLatin, to: .cirth).glyphOutput)
        #expect(RunicPresentationResolver.resolve(RunicPresentationInput(quote: updated, script: .cirth), currentCache: nil).isRenderable)
    }
}
