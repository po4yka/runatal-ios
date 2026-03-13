//
//  TranslationQualityRegressionTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

@testable import RunicQuotes
import Testing

@Suite(.tags(.dataset))
struct TranslationQualityRegressionTests {
    private let provider = AssetTranslationDatasetProvider()
    private let service = HistoricalTranslationService()

    @Test
    func goldCorpusBenchmarksRemainStable() throws {
        let benchmarks = self.provider.goldCorpus().benchmarks
        #expect(!benchmarks.isEmpty)

        for benchmark in benchmarks {
            for expectation in benchmark.expectations {
                let script = try #require(RunicScript(translationScriptName: expectation.script))
                let fidelity = try #require(TranslationFidelity(rawValue: expectation.fidelity))
                let variant = expectation.requestedVariant.flatMap(YoungerFutharkVariant.init(rawValue:)) ?? .longBranch

                let result = self.service.translate(
                    text: benchmark.sourceText,
                    script: script,
                    fidelity: fidelity,
                    youngerVariant: variant,
                    sourceLanguage: .english,
                )

                #expect(result.normalizedForm == expectation.normalizedForm)
                #expect(result.diplomaticForm == expectation.diplomaticForm)
                #expect(result.glyphOutput == expectation.glyphOutput)
                #expect(result.resolutionStatus.rawValue == expectation.resolutionStatus)
                #expect(result.evidenceTier.rawValue == expectation.evidenceTier)
                #expect(result.supportLevel.rawValue == expectation.supportLevel)
                #expect(result.attestationRefs == expectation.attestationRefs)

                let warningsBlob = result.userFacingWarnings.joined(separator: " ")
                for fragment in expectation.warningFragments {
                    #expect(warningsBlob.localizedCaseInsensitiveContains(fragment))
                }
            }
        }
    }
}

private extension RunicScript {
    init?(translationScriptName: String) {
        switch translationScriptName {
        case "ELDER_FUTHARK":
            self = .elder
        case "YOUNGER_FUTHARK":
            self = .younger
        case "CIRTH":
            self = .cirth
        default:
            return nil
        }
    }
}
