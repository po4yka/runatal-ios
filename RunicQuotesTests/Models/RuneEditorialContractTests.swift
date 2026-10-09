//
//  RuneEditorialContractTests.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
@testable import RunicQuotes
import XCTest

final class RuneEditorialContractTests: XCTestCase {
    func testEveryReferenceGlyphExposesActualSourceScopeAndNameEvidence() {
        for rune in RuneInfo.elderFuthark + RuneInfo.youngerFuthark + RuneInfo.cirth {
            XCTAssertFalse(rune.historicalNote.isEmpty, rune.id)
            XCTAssertEqual(rune.referenceSources.count, 2, rune.id)
            XCTAssertTrue(rune.referenceSources.allSatisfy { URL(string: $0.url)?.scheme == "https" }, rune.id)
        }
        XCTAssertTrue(RuneInfo.elderFuthark.allSatisfy { $0.nameEvidence == .comparativeReconstruction })
        XCTAssertTrue(RuneInfo.youngerFuthark.allSatisfy { $0.nameEvidence == .medievalPoemTradition })
        XCTAssertTrue(RuneInfo.cirth.allSatisfy { $0.nameEvidence == .fictionalScript })
    }

    func testDisputedNamesRemainUncertainAndModernPromptsStaySeparate() throws {
        let perthro = try XCTUnwrap(RuneInfo.elderFuthark.first { $0.id == "elder-perthro" })
        XCTAssertEqual(perthro.meaning, "Uncertain")
        XCTAssertTrue(perthro.historicalNote.contains("rather than an established translation"))
        XCTAssertNotNil(perthro.modernReflection)
        let algiz = try XCTUnwrap(RuneInfo.elderFuthark.first { $0.id == "elder-algiz" })
        XCTAssertTrue(algiz.meaning.contains("Uncertain"))
        XCTAssertFalse(algiz.meaning.contains("Protection"))
        XCTAssertTrue(algiz.historicalNote.contains("does not establish"))
        XCTAssertTrue(RuneInfo.cirth.allSatisfy { $0.modernReflection == nil })
        XCTAssertTrue(RuneInfo.cirth.allSatisfy { $0.historicalNote.contains("private-use") })
    }
}
