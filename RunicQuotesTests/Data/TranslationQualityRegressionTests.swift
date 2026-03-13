//
//  TranslationQualityRegressionTests.swift
//  RunicQuotesTests
//
//  Created by Codex on 2026-03-13.
//

import XCTest
@testable import RunicQuotes

final class TranslationQualityRegressionTests: XCTestCase {
    private let provider = AssetTranslationDatasetProvider()
    private let service = HistoricalTranslationService()

    func testGoldCorpusBenchmarksRemainStable() throws {
        let benchmarks = provider.goldCorpus().benchmarks
        XCTAssertFalse(benchmarks.isEmpty)

        for benchmark in benchmarks {
            for expectation in benchmark.expectations {
                let script = try XCTUnwrap(RunicScript(translationScriptName: expectation.script))
                let fidelity = try XCTUnwrap(TranslationFidelity(rawValue: expectation.fidelity))
                let variant = expectation.requestedVariant.flatMap(YoungerFutharkVariant.init(rawValue:)) ?? .longBranch

                let result = service.translate(
                    text: benchmark.sourceText,
                    script: script,
                    fidelity: fidelity,
                    youngerVariant: variant,
                    sourceLanguage: .english
                )

                XCTAssertEqual(result.normalizedForm, expectation.normalizedForm, benchmark.id)
                XCTAssertEqual(result.diplomaticForm, expectation.diplomaticForm, benchmark.id)
                XCTAssertEqual(result.glyphOutput, expectation.glyphOutput, benchmark.id)
                XCTAssertEqual(result.resolutionStatus.rawValue, expectation.resolutionStatus, benchmark.id)
                XCTAssertEqual(result.evidenceTier.rawValue, expectation.evidenceTier, benchmark.id)
                XCTAssertEqual(result.supportLevel.rawValue, expectation.supportLevel, benchmark.id)
                XCTAssertEqual(result.attestationRefs, expectation.attestationRefs, benchmark.id)

                let warningsBlob = result.userFacingWarnings.joined(separator: " ")
                for fragment in expectation.warningFragments {
                    XCTAssertTrue(
                        warningsBlob.localizedCaseInsensitiveContains(fragment),
                        "Expected warning fragment '\(fragment)' for \(benchmark.id)"
                    )
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
