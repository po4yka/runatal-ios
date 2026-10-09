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
}
