//
//  QuoteViewModelTranslationTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
@testable import RunicQuotes
import SwiftData
import Testing

@MainActor
@Suite(.serialized, .tags(.viewModel))
struct QuoteViewModelTranslationTests {
    @Test
    func savedHistoricalArtifactRetainsExactGlyphsAndRecordedEvidenceAcrossEngineChange() async throws {
        let context = try TestSupport.makeModelContext()
        let current = HistoricalTranslationService().translate(text: "Harja", script: .elder, fidelity: .strict)
        #expect(current.isAvailable)
        let artifact = try self.oldArtifact(current)
        let record = try SwiftDataQuoteRepository(modelContext: context).createQuote(
            textLatin: current.sourceText, author: "Reader", source: nil, collection: .stoic,
            storedRunic: RunicTextBundle(elder: artifact.glyphOutput, younger: nil, cirth: nil), translations: [artifact],
        )
        let viewModel = self.makeViewModel(context: context)
        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })
        #expect(viewModel.state.currentQuoteID == record.id)
        #expect(viewModel.state.runicText == artifact.glyphOutput)
        #expect(viewModel.state.runicPresentationSource == .savedHistoricalArtifact)
        #expect(viewModel.state.savedTranslationArtifact == artifact)
        #expect(viewModel.state.runicPresentationSource.evidenceLabel(artifact.evidenceTier).hasPrefix("Recorded evidence:"))
        #expect(viewModel.state.runicWarnings.contains { $0.contains("not been rechecked") })
    }

    @Test
    func corruptOriginalAssessmentPreservesCustomOutputAheadOfCurrentCache() async throws {
        let context = try TestSupport.makeModelContext()
        let quote = Quote(textLatin: "The wolf hunts at night", author: "Reader", collection: .stoic, isUserGenerated: true)
        quote.runicYounger = "ᛚᛖᚷᚨᚲᛁ"
        quote.storedTranslationMetadataData = Data("corrupt original assessment".utf8)
        context.insert(quote)
        try context.save()
        let current = HistoricalTranslationService().translate(text: quote.textLatin, script: .younger, fidelity: .strict)
        #expect(current.isAvailable)
        try SwiftDataTranslationRepository(modelContext: context).cache(result: current, for: quote.id, sourceText: quote.textLatin)
        try SwiftDataUserPreferencesRepository(modelContext: context).apply([.script(.younger)])
        let viewModel = self.makeViewModel(context: context)
        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })
        #expect(viewModel.state.runicText == quote.runicYounger)
        #expect(viewModel.state.runicPresentationSource == .savedRunicText)
        #expect(viewModel.state.runicEvidenceTier == nil)
        #expect(viewModel.state.runicWarnings.contains { $0.contains("assessment") })
    }

    @Test
    func unknownCirthEncodingKeepsOriginalDataWithoutRenderingTofuAsValidatedOutput() async throws {
        let context = try TestSupport.makeModelContext()
        let quote = Quote(textLatin: "Original text", author: "Reader", collection: .stoic, isUserGenerated: true)
        quote.runicCirth = "\u{E000}\u{E011}"
        quote.cirthEncodingRaw = "CIRTH_UNKNOWN_V0"
        context.insert(quote)
        try context.save()
        try SwiftDataUserPreferencesRepository(modelContext: context).apply([.script(.cirth)])
        let viewModel = self.makeViewModel(context: context)
        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })
        #expect(viewModel.state.runicText == quote.runicCirth)
        #expect(!viewModel.state.isRunicRenderingAvailable)
        #expect(viewModel.state.runicEvidenceTier == nil)
        #expect(!viewModel.state.runicWarnings.isEmpty)
    }

    @Test
    func savedGeneratedPartialTransliterationRetainsItsActualUnresolvedWarning() async throws {
        let context = try TestSupport.makeModelContext()
        let text = "Rune 💀"
        let generated = RunicTransliterator.transliterate(text, to: .elder)
        #expect(!generated.warnings.isEmpty)
        _ = try SwiftDataQuoteRepository(modelContext: context).createQuote(
            textLatin: text, author: "Reader", source: nil, collection: .stoic,
            storedRunic: RunicTextBundle(elder: generated.glyphOutput, younger: nil, cirth: nil), translations: [],
        )
        let viewModel = self.makeViewModel(context: context)
        viewModel.onAppear()
        #expect(await TestSupport.eventually { !viewModel.state.isLoading })
        #expect(viewModel.state.latinText == text)
        #expect(viewModel.state.runicText == generated.glyphOutput)
        #expect(!viewModel.state.runicWarnings.isEmpty)
        #expect(viewModel.state.runicEvidenceTier == nil)
    }

    private func makeViewModel(context: ModelContext) -> QuoteViewModel {
        QuoteViewModel(
            quoteProvider: QuoteProvider(modelContainer: context.container),
            translationProvider: TranslationProvider(modelContainer: context.container),
            preferencesRepository: SwiftDataUserPreferencesRepository(modelContext: context),
        )
    }

    private func oldArtifact(_ current: TranslationResult) throws -> TranslationResult {
        var object = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(current)) as? [String: Any])
        object["engineVersion"] = "previous-engine"
        object["datasetVersion"] = "previous-dataset"
        return try JSONDecoder().decode(TranslationResult.self, from: JSONSerialization.data(withJSONObject: object))
    }
}
