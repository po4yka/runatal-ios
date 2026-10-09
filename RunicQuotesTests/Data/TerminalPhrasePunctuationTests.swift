//
//  TerminalPhrasePunctuationTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
@testable import RunicQuotes
import Testing

@Suite(.tags(.dataset))
struct TerminalPhrasePunctuationTests {
    @Test
    func genuineAttestedContentAcceptsModernTerminalPunctuationWithoutClaimingItsAttestation() throws {
        let entries = try QuoteSeedCatalog.load().filter { $0.id.hasPrefix("builtin-inscription-") && !$0.id.hasSuffix("dr41") }
        #expect(entries.count == 3)
        let service = HistoricalTranslationService()
        for entry in entries {
            let script: RunicScript = entry.id.contains("-elder-") ? .elder : .younger
            let core = PhraseMatchInput(entry.textLatin).coreText
            for suffix in [".", "!", "?"] {
                let request = TranslationRequest(sourceText: core + suffix, script: script, evidenceCap: .attestedOnly)
                let result = service.translate(request)
                #expect(result.isAvailable)
                #expect(result.sourceText == core + suffix)
                #expect(result.evidenceTier == .attested)
                #expect(result.glyphOutput.hasSuffix(suffix))
                #expect(result.diplomaticForm.hasSuffix(suffix))
                #expect(result.normalizedForm.hasSuffix(suffix))
                #expect(result.userFacingWarnings.contains { $0.contains("modern input punctuation") })
                #expect(result.tokenBreakdown.last?.provenance.isEmpty == true)
                #expect(result.tokenBreakdown.last?.resolutionStatus == .reconstructed)
            }
        }
    }

    @Test
    func reconstructedTemplatesAndGoldKeepTheirTierAndExactPunctuation() throws {
        let entry = try #require(QuoteSeedCatalog.load().first { $0.id.hasSuffix("dr41") })
        let source = PhraseMatchInput(entry.textLatin).coreText + "?"
        let service = HistoricalTranslationService()
        let restored = service.translate(TranslationRequest(sourceText: source, script: .younger))
        #expect(restored.isAvailable)
        #expect(restored.evidenceTier == .reconstructed)
        #expect(restored.glyphOutput.hasSuffix("?"))
        #expect(!service.translate(TranslationRequest(sourceText: source, script: .younger, evidenceCap: .attestedOnly)).isAvailable)
        let gold = service.translate(text: "The wolf hunts at night!", script: .younger, fidelity: .strict)
        #expect(gold.isAvailable)
        #expect(gold.derivationKind == .goldExample)
        #expect(gold.evidenceTier == .reconstructed)
        #expect(gold.glyphOutput.hasSuffix("!"))
        #expect(gold.sourceText == "The wolf hunts at night!")
    }

    @Test
    func internalPunctuationAndAdditionalWordsDoNotGainFullPhraseAttestation() {
        let service = HistoricalTranslationService()
        for source in ["Harja,", "Harja:", "Harja. Wolf", "Harja! changed", "Harja extra words"] {
            let result = service.translate(TranslationRequest(sourceText: source, script: .elder, evidenceCap: .attestedOnly))
            #expect(!result.isAvailable)
            #expect(result.sourceText == source)
        }
        #expect(PhraseMatchInput("Harja.").key == "harja")
        #expect(PhraseMatchInput("Harja. Wolf").key == "harja. wolf")
        #expect(PhraseMatchInput("Harja,").key == "harja,")
    }
}
