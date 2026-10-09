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
    }

    func testSmartApostrophePreservesNegationLikeStraightContraction() {
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

    func testAttestedOnlyAcceptsNamedInscriptionAndRejectsEveryFallback() {
        let recorded = self.service.translate(text: "Harja", script: .elder, evidenceCap: .attestedOnly)
        XCTAssertEqual(recorded.glyphOutput, "ᚺᚨᚱᛃᚨ")
        XCTAssertEqual(recorded.evidenceTier, .attested)
        for script in RunicScript.allCases {
            let unknown = self.service.translate(text: "signal", script: script, fidelity: .readable, evidenceCap: .attestedOnly)
            XCTAssertEqual(unknown.resolutionStatus, .unavailable)
            XCTAssertTrue(unknown.glyphOutput.isEmpty)
            XCTAssertEqual(unknown.confidence, 0)
        }
        XCTAssertFalse(self.service.translate(text: "you", script: .younger, evidenceCap: .attestedOnly).isAvailable)
        XCTAssertFalse(self.service.translate(text: "Wolf", script: .elder, evidenceCap: .attestedOnly).isAvailable)
        let restored = self.service.translate(text: "King Gorm made this monument in memory of Thyra, his wife, Denmark's adornment.", script: .younger, evidenceCap: .attestedOnly)
        XCTAssertFalse(restored.isAvailable)
        let exact = self.service.translate(text: "King Harald ordered these monuments made in memory of Gorm, his father, and Thyra, his mother.", script: .younger, evidenceCap: .attestedOnly)
        XCTAssertTrue(exact.isAvailable)
        XCTAssertEqual(exact.evidenceTier, .attested)
    }

    func testKnownLexemesTranslateBeforeCapitalizedNameFallback() {
        for fidelity in [TranslationFidelity.readable, .decorative] {
            let lower = self.service.translate(text: "wolf", script: .younger, fidelity: fidelity)
            let title = self.service.translate(text: "Wolf", script: .younger, fidelity: fidelity)
            XCTAssertEqual(title.normalizedForm, "úlfr")
            XCTAssertEqual(title.normalizedForm, lower.normalizedForm)
            XCTAssertEqual(title.glyphOutput, "ᚢᛚᚠᚱ")
            XCTAssertFalse(title.notes.contains { $0.contains("uncatalogued proper name") })
        }
        let unknownName = self.service.translate(text: "Zelda", script: .younger, fidelity: .readable)
        XCTAssertEqual(unknownName.evidenceTier, .approximate)
        XCTAssertTrue(unknownName.notes.contains { $0.contains("uncatalogued proper name") })
    }

    func testIrregularPastCopulaKeepsItsTenseThroughLemmaNormalization() {
        let present = self.service.translate(text: "He is", script: .younger)
        let past = self.service.translate(text: "He was", script: .younger)
        XCTAssertEqual(present.normalizedForm, "hann er")
        XCTAssertEqual(past.normalizedForm, "hann var")
        XCTAssertEqual(past.glyphOutput, "ᚼᛅᚾ ᚢᛅᚱ")
        XCTAssertEqual(past.resolutionStatus, .reconstructed)
        XCTAssertTrue(past.isAvailable)
        XCTAssertNotEqual(past.glyphOutput, present.glyphOutput)
    }

    func testLexicalHaveKeepsPossessionAndGovernsAccusativeObject() {
        let present = self.service.translate(text: "He has a wolf", script: .younger)
        XCTAssertEqual(present.normalizedForm, "hann hefir úlf")
        XCTAssertTrue(present.isAvailable)
        XCTAssertEqual(present.evidenceTier, .reconstructed)
        XCTAssertTrue(present.provenance.contains { $0.sourceID == "barnes_nion" })
        XCTAssertFalse(present.notes.contains { $0.contains("Auxiliary chains") })
        XCTAssertEqual(self.service.translate(text: "He had a wolf", script: .younger).normalizedForm, "hann hafði úlf")
    }

    func testLexicalVerbDoesNotCollapseAcrossNounPhraseOrPunctuation() {
        for input in ["He has a wolf and hunts", "He has a wolf. He hunts"] {
            let result = self.service.translate(text: input, script: .younger, fidelity: .readable)
            XCTAssertTrue(result.tokenBreakdown.contains { $0.sourceToken == "has" && $0.normalizedToken == "hefir" })
        }
        let auxiliary = self.service.translate(text: "He does not hunt", script: .younger)
        XCTAssertFalse(auxiliary.tokenBreakdown.contains { $0.sourceToken == "does" })
        XCTAssertTrue(auxiliary.tokenBreakdown.contains { $0.sourceToken == "hunt" })
    }

    func testDiphthongsRewriteBeforeSingleVowelReduction() {
        let hunt = self.service.translate(text: "hunt", script: .younger)
        XCTAssertEqual(hunt.normalizedForm, "veiða")
        XCTAssertEqual(hunt.diplomaticForm, "vaiþa")
        XCTAssertEqual(hunt.glyphOutput, "ᚢᛅᛁᚦᛅ")
        let one = self.service.translate(text: "one", script: .younger)
        XCTAssertEqual(one.diplomaticForm, "ain")
        XCTAssertEqual(one.glyphOutput, "ᛅᛁᚾ")
        let preserved = self.service.translate(text: "ey", script: .younger, fidelity: .decorative)
        XCTAssertEqual(preserved.diplomaticForm, "au")
        XCTAssertEqual(preserved.glyphOutput, "ᛅᚢ")
        XCTAssertEqual(preserved.evidenceTier, .approximate)
    }

    func testRepeatedWordBreakdownPreservesEveryOrderedOccurrence() throws {
        let result = self.service.translate(text: "wolf wolf wolf", script: .younger)
        XCTAssertEqual(result.tokenBreakdown.count, 3)
        XCTAssertEqual(result.tokenBreakdown.map(\.sourceToken), ["wolf", "wolf", "wolf"])
        XCTAssertEqual(result.glyphOutput, "ᚢᛚᚠᚱ ᚢᛚᚠᚱ ᚢᛚᚠᚱ")
        let stored = try JSONDecoder().decode(TranslationResult.self, from: JSONEncoder().encode(result))
        XCTAssertEqual(stored.tokenBreakdown, result.tokenBreakdown)
    }

    func testElderFallbackNeverRelabelsOldNorseParaphraseAsProtoNorse() {
        let computer = self.service.translate(text: "computer", script: .elder, fidelity: .readable)
        XCTAssertEqual(computer.normalizedForm, "computer")
        XCTAssertEqual(computer.glyphOutput, "ᚲᛟᛗᛈᚢᛏᛖᚱ")
        XCTAssertEqual(computer.historicalStage, .modernEnglish)
        XCTAssertEqual(computer.evidenceTier, .approximate)
        XCTAssertFalse(computer.normalizedForm.contains("reiknandi"))
        let ancient = self.service.translate(text: "wolf", script: .elder, fidelity: .readable)
        XCTAssertEqual(ancient.normalizedForm, "wulfaz")
        XCTAssertEqual(ancient.historicalStage, .protoNorse)
        let mixed = self.service.translate(text: "wolf computer", script: .elder, fidelity: .readable)
        XCTAssertEqual(mixed.historicalStage, .mixed)
        XCTAssertTrue(mixed.userFacingWarnings.contains { $0.contains("meaning has not been translated") })
        let younger = self.service.translate(text: "computer", script: .younger, fidelity: .readable)
        XCTAssertEqual(younger.normalizedForm, "reiknandi vél")
        XCTAssertEqual(younger.historicalStage, .oldNorse)
    }

}
