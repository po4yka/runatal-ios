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
        XCTAssertTrue(RunicTransliterator.transliterate("hokv", to: .elder) == "ᚺᛟᚲᚠ")
        let alphabet = Set("ᚠᚢᚦᚨᚱᚲᚷᚹᚺᚾᛁᛃᛇᛈᛉᛊᛏᛒᛖᛗᛚᛜᛞᛟ")
        XCTAssertTrue(RunicTransliterator.transliterate("abcdefghijklmnopqrstuvwxyz", to: .elder).allSatisfy(alphabet.contains))
    }

    func testYoungerOutputAndReferenceUseLongBranchGraphs() {
        XCTAssertEqual(RunicTransliterator.transliterate("adhejmsoy", to: .younger), "ᛅᛏᚼᛁᛁᛘᛋᚢᚢ")
        let alphabet = Set("ᚠᚢᚦᚬᚱᚴᚼᚾᛁᛅᛋᛏᛒᛘᛚᛦ")
        XCTAssertTrue(RunicTransliterator.transliterate("abcdefghijklmnopqrstuvwxyz", to: .younger).allSatisfy(alphabet.contains))
        XCTAssertEqual(Set(RuneInfo.youngerFuthark.map(\.glyph)), Set(alphabet.map(String.init)))
    }

}
