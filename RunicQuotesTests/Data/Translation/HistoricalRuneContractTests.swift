//
//  HistoricalRuneContractTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
@testable import RunicQuotes
import XCTest

final class HistoricalRuneContractTests: XCTestCase {
    private let service = HistoricalTranslationService()

    func testStrictYoungerConvertsHistoricalLongVowelsToRunes() {
        XCTAssertEqual(self.service.translate(text: "you", script: .younger).glyphOutput, "ᚦᚢ")
        XCTAssertEqual(self.service.translate(text: "in", script: .younger).glyphOutput, "ᛁ")
        XCTAssertEqual(self.service.translate(text: "wolf", script: .younger).glyphOutput, "ᚢᛚᚠᚱ")
        for input in ["you", "in", "wolf"] {
            let result = self.service.translate(text: input, script: .younger)
            XCTAssertTrue(result.isAvailable)
            XCTAssertFalse(result.glyphOutput.unicodeScalars.contains { $0.properties.isAlphabetic && $0.value < 0x16A0 })
        }
    } func testSmartApostrophePreservesNegationLikeStraightContraction() {
        let straight = self.service.translate(text: "He can't hunt", script: .younger, fidelity: .readable)
        let smart = self.service.translate(text: "He can’t hunt", script: .younger, fidelity: .readable)
        XCTAssertEqual(smart.normalizedForm, straight.normalizedForm)
        XCTAssertEqual(smart.glyphOutput, straight.glyphOutput)
        XCTAssertTrue(smart.tokenBreakdown.contains { $0.sourceToken == "not" })
        XCTAssertTrue(smart.normalizedForm.contains("eigi"))
    }

    func testNumbersAndSymbolsRemainVisibleInHistoricalOutput() {
        let numbered = self.service.translate(text: "wolf 2", script: .younger)
        XCTAssertEqual(numbered.glyphOutput, "ᚢᛚᚠᚱ 2")
        let joined = self.service.translate(text: "wolf+king", script: .younger)
        XCTAssertEqual(joined.glyphOutput, "ᚢᛚᚠᚱ + ᚴᚢᚾᚢᚾᚴᚱ")
        XCTAssertEqual(joined.supportLevel, .partial)
        XCTAssertTrue(joined.userFacingWarnings.contains { $0.contains("preserved literally") })
    }

    func testExtendedGraphemeSymbolsArePreservedWithoutSplitting() {
        let result = self.service.translate(text: "wolf 👩‍💻", script: .younger, fidelity: .readable)
        XCTAssertEqual(result.glyphOutput, "ᚢᛚᚠᚱ 👩‍💻")
    }

    func testNamedInscriptionTemplatesExposeRealAttestationAndReferences() {
        let horn = self.service.translate(text: "I, Hlewagastiz Holtijaz, made the horn.", script: .elder)
        XCTAssertEqual(horn.glyphOutput, "ᛖᚲ ᚺᛚᛖᚹᚨᚷᚨᛊᛏᛁᛉ ᚺᛟᛚᛏᛁᛃᚨᛉ ᚺᛟᚱᚾᚨ ᛏᚨᚹᛁᛞᛟ")
        XCTAssertEqual(horn.evidenceTier, .attested)
        XCTAssertEqual(horn.attestationRefs, ["elder_gallehus_dr12-reference"])
        let name = self.service.translate(text: "Harja", script: .elder)
        XCTAssertEqual(name.glyphOutput, "ᚺᚨᚱᛃᚨ")
        XCTAssertEqual(name.evidenceTier, .attested)
        let restored = self.service.translate(text: "King Gorm made this monument in memory of Thyra, his wife, Denmark's adornment.", script: .younger)
        XCTAssertTrue(restored.isAvailable)
        XCTAssertEqual(restored.evidenceTier, .reconstructed)
        let recorded = self.service.translate(text: "King Harald ordered these monuments made in memory of Gorm, his father, and Thyra, his mother.", script: .younger)
        XCTAssertTrue(recorded.isAvailable)
        XCTAssertEqual(recorded.evidenceTier, .attested)
        XCTAssertEqual(recorded.attestationRefs, ["younger_jelling_dr42-reference"])
        XCTAssertEqual(self.service.translate(text: "Wolf", script: .elder).evidenceTier, .reconstructed)
    }

}
