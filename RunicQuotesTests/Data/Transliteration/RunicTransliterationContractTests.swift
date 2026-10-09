//
//  RunicTransliterationContractTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

@testable import RunicQuotes
import XCTest

final class RunicTransliterationContractTests: XCTestCase {
    func testElderOutputUsesCanonicalHistoricalGraphs() {
        XCTAssertTrue(RunicTransliterator.transliterate("hokv", to: .elder).glyphOutput == "ᚺᛟᚲᚠ")
        let alphabet = Set("ᚠᚢᚦᚨᚱᚲᚷᚹᚺᚾᛁᛃᛇᛈᛉᛊᛏᛒᛖᛗᛚᛜᛞᛟ")
        XCTAssertTrue(RunicTransliterator.transliterate("abcdefghijklmnopqrstuvwxyz", to: .elder).glyphOutput.allSatisfy(alphabet.contains))
    }

    func testYoungerOutputAndReferenceUseLongBranchGraphs() {
        XCTAssertEqual(RunicTransliterator.transliterate("adhejmsoy", to: .younger).glyphOutput, "ᛅᛏᚼᛁᛁᛘᛋᚢᚢ")
        let alphabet = Set("ᚠᚢᚦᚬᚱᚴᚼᚾᛁᛅᛋᛏᛒᛘᛚᛦ")
        XCTAssertTrue(RunicTransliterator.transliterate("abcdefghijklmnopqrstuvwxyz", to: .younger).glyphOutput.allSatisfy(alphabet.contains))
        XCTAssertEqual(Set(RuneInfo.youngerFuthark.map(\.glyph)), Set(alphabet.map(String.init)))
    }

    func testLatinNormalizationConvertsAccentsAndThornWithoutDroppingText() {
        XCTAssertEqual(RunicTransliterator.transliterate("café Þór", to: .elder).glyphOutput, "ᚲᚨᚠᛖ ᚦᛟᚱ")
        XCTAssertEqual(RunicTransliterator.transliterate("E\u{0301}", to: .elder).glyphOutput, "ᛖ")
        XCTAssertEqual(RunicTransliterator.transliterate("æœßøł", to: .elder).glyphOutput, "ᚨᛖᛟᛖᛊᛊᛟᛚ")
        XCTAssertEqual(RunicTransliterator.transliterate("x", to: .elder).glyphOutput, "ᚲᛊ")
        XCTAssertEqual(RunicTransliterator.transliterate("x", to: .younger).glyphOutput, "ᚴᛋ")
    }

    func testUnsupportedGraphemesRemainExactAndReported() {
        let result = RunicTransliterator.transliterate("ВОЛК 🙂 Ω", to: .elder)
        XCTAssertEqual(result.glyphOutput, "ВОЛК 🙂 Ω")
        XCTAssertEqual(result.unresolvedCharacters, ["В", "О", "Л", "К", "🙂", "Ω"])
        XCTAssertFalse(result.warnings.isEmpty)
    }

}
