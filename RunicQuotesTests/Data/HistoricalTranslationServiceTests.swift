//
//  HistoricalTranslationServiceTests.swift
//  RunicQuotesTests
//
//  Created by Codex on 2026-03-13.
//

import XCTest
@testable import RunicQuotes

final class HistoricalTranslationServiceTests: XCTestCase {
    private let service = HistoricalTranslationService()

    func testStrictYoungerTranslationUsesCuratedGoldExample() {
        let result = service.translate(
            text: "The wolf hunts at night",
            script: .younger,
            fidelity: .strict
        )

        XCTAssertEqual(result.derivationKind, .goldExample)
        XCTAssertEqual(result.historicalStage, .oldNorse)
        XCTAssertEqual(result.datasetVersion, "2026.03-curated-v3")
        XCTAssertTrue(result.glyphOutput.contains("ᚢᛚᚠᚱ"))
        XCTAssertTrue(result.provenance.contains(where: { $0.referenceID == "yf_ref_wolf_night" }))
    }

    func testStrictElderTranslationReturnsUnavailableForUnsupportedWords() {
        let result = service.translate(
            text: "signal",
            script: .elder,
            fidelity: .strict
        )

        XCTAssertEqual(result.resolutionStatus, .unavailable)
        XCTAssertEqual(result.unresolvedTokens, ["signal"])
        XCTAssertTrue(result.glyphOutput.isEmpty)
    }

    func testCirthPhraseMappingIsPreferredWhenCurated() {
        let result = service.translate(
            text: "Under the mountain",
            script: .cirth,
            fidelity: .strict
        )

        XCTAssertEqual(result.derivationKind, .phraseTemplate)
        XCTAssertEqual(result.diplomaticForm, "u·n·d·e·r th·e m·ou·n·t·ai·n")
        XCTAssertTrue(result.provenance.contains(where: { $0.referenceID == "cirth_ref_under_mountain" }))
        XCTAssertFalse(result.glyphOutput.isEmpty)
    }

    func testYoungerVariantChangesGlyphsOnly() {
        let longBranch = service.translate(
            text: "king night",
            script: .younger,
            fidelity: .strict,
            youngerVariant: .longBranch
        )
        let shortTwig = service.translate(
            text: "king night",
            script: .younger,
            fidelity: .strict,
            youngerVariant: .shortTwig
        )

        XCTAssertEqual(longBranch.normalizedForm, shortTwig.normalizedForm)
        XCTAssertEqual(longBranch.diplomaticForm, shortTwig.diplomaticForm)
        XCTAssertNotEqual(longBranch.glyphOutput, shortTwig.glyphOutput)
    }

    func testUnsupportedLanguageRejectsWithGuidance() {
        let result = service.translate(
            text: "волк ночью",
            script: .younger,
            fidelity: .strict
        )

        XCTAssertEqual(result.supportLevel, .unsupported)
        XCTAssertEqual(result.evidenceTier, .unsupported)
        XCTAssertEqual(result.inputLanguage, .unsupported)
        XCTAssertTrue(result.userFacingWarnings.contains(where: { $0.contains("English input only") }))
    }

    func testReadableYoungerHandlesNegationAndCopula() {
        let result = service.translate(
            text: "He is not lost",
            script: .younger,
            fidelity: .readable
        )

        XCTAssertTrue(result.isAvailable)
        XCTAssertEqual(result.inputLanguage, .english)
        XCTAssertTrue(result.tokenBreakdown.contains(where: { $0.sourceToken.lowercased() == "not" }))
    }

    func testReadableYoungerMergesConfiguredMultiwordExpression() {
        let result = service.translate(
            text: "Honor the old ways",
            script: .younger,
            fidelity: .readable
        )

        XCTAssertTrue(result.isAvailable)
        XCTAssertTrue(result.userFacingWarnings.contains(where: { $0.contains("Imperative") }))
        XCTAssertTrue(result.tokenBreakdown.contains(where: { $0.sourceToken.lowercased() == "old ways" }))
    }
}
