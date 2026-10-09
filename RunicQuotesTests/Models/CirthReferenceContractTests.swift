//
//  CirthReferenceContractTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

@testable import RunicQuotes
import XCTest

final class CirthReferenceContractTests: XCTestCase {
    func testEreborReferenceUsesActualCerthNumbersAcrossGraphVariants() throws {
        // Independent Appendix E numbers; PUA scalar ordinal is not the certh number.
        let expected = [
            (12, "r", "\u{E08B}"),
            (14, "j", "\u{E08D}"),
            (17, "ks", "\u{E090}"),
            (39, "i", "\u{E0A7}"),
            (43, "z", "\u{E0AB}"),
            (46, "e", "\u{E0AF}"),
            (48, "a", "\u{E0B1}"),
            (54, "s", "\u{E0B9}"),
            (57, "ps", "\u{E0BE}"),
        ]
        for (number, sound, glyph) in expected {
            let rune = try XCTUnwrap(RuneInfo.cirth.first { $0.id == "cirth-erebor-\(number)" })
            XCTAssertEqual(rune.name, "Certh \(number)")
            XCTAssertEqual(rune.sound, sound)
            XCTAssertEqual(rune.glyph, glyph)
        }
    }

    func testReferenceContainsUniqueGraphsAndExplicitModeDifferences() throws {
        XCTAssertEqual(RuneInfo.cirth.count, 50)
        XCTAssertEqual(Set(RuneInfo.cirth.map(\.id)).count, 50)
        XCTAssertEqual(Set(RuneInfo.cirth.map(\.glyph)).count, 50)
        let z = try XCTUnwrap(CirthGraph.erebor.first { $0.number == 43 })
        XCTAssertTrue(z.modeNote.contains("Moria"))
        XCTAssertTrue(z.modeNote.contains("long u"))
        XCTAssertTrue(CirthGraph.erebor.contains { $0.number == 37 && $0.modeNote.contains("question mark") })
    }
}
