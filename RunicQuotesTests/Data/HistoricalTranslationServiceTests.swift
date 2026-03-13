//
//  HistoricalTranslationServiceTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

@testable import RunicQuotes
import Testing

@Suite(.tags(.repository))
struct HistoricalTranslationServiceTests {
    private let service = HistoricalTranslationService()

    @Test
    func strictYoungerTranslationUsesCuratedGoldExample() {
        let result = self.service.translate(
            text: "The wolf hunts at night",
            script: .younger,
            fidelity: .strict,
        )

        #expect(result.derivationKind == .goldExample)
        #expect(result.historicalStage == .oldNorse)
        #expect(result.datasetVersion == "2026.03-curated-v3")
        #expect(result.glyphOutput.contains("ᚢᛚᚠᚱ"))
        #expect(result.provenance.contains { $0.referenceID == "yf_ref_wolf_night" })
    }

    @Test
    func strictElderTranslationReturnsUnavailableForUnsupportedWords() {
        let result = self.service.translate(
            text: "signal",
            script: .elder,
            fidelity: .strict,
        )

        #expect(result.resolutionStatus == .unavailable)
        #expect(result.unresolvedTokens == ["signal"])
        #expect(result.glyphOutput.isEmpty)
    }

    @Test
    func cirthPhraseMappingIsPreferredWhenCurated() {
        let result = self.service.translate(
            text: "Under the mountain",
            script: .cirth,
            fidelity: .strict,
        )

        #expect(result.derivationKind == .phraseTemplate)
        #expect(result.diplomaticForm == "u·n·d·e·r th·e m·ou·n·t·ai·n")
        #expect(result.provenance.contains { $0.referenceID == "cirth_ref_under_mountain" })
        #expect(!result.glyphOutput.isEmpty)
    }

    @Test
    func youngerVariantChangesGlyphsOnly() {
        let longBranch = self.service.translate(
            text: "king night",
            script: .younger,
            fidelity: .strict,
            youngerVariant: .longBranch,
        )
        let shortTwig = self.service.translate(
            text: "king night",
            script: .younger,
            fidelity: .strict,
            youngerVariant: .shortTwig,
        )

        #expect(longBranch.normalizedForm == shortTwig.normalizedForm)
        #expect(longBranch.diplomaticForm == shortTwig.diplomaticForm)
        #expect(longBranch.glyphOutput != shortTwig.glyphOutput)
    }

    @Test
    func unsupportedLanguageRejectsWithGuidance() {
        let result = self.service.translate(
            text: "волк ночью",
            script: .younger,
            fidelity: .strict,
        )

        #expect(result.supportLevel == .unsupported)
        #expect(result.evidenceTier == .unsupported)
        #expect(result.inputLanguage == .unsupported)
        #expect(result.userFacingWarnings.contains { $0.contains("English input only") })
    }

    @Test
    func readableYoungerHandlesNegationAndCopula() {
        let result = self.service.translate(
            text: "He is not lost",
            script: .younger,
            fidelity: .readable,
        )

        #expect(result.isAvailable)
        #expect(result.inputLanguage == .english)
        #expect(result.tokenBreakdown.contains { $0.sourceToken.lowercased() == "not" })
    }

    @Test
    func readableYoungerMergesConfiguredMultiwordExpression() {
        let result = self.service.translate(
            text: "Honor the old ways",
            script: .younger,
            fidelity: .readable,
        )

        #expect(result.isAvailable)
        #expect(result.userFacingWarnings.contains { $0.contains("Imperative") })
        #expect(result.tokenBreakdown.contains { $0.sourceToken.lowercased() == "old ways" })
    }
}
