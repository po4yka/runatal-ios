//
//  RunicTransliteratorPerformanceTests.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

@testable import RunicQuotes
import XCTest

final class RunicTransliteratorPerformanceTests: XCTestCase {
    func testTransliterationPerformance() {
        let longText = String(repeating: "fortune favors the bold ", count: 100)

        measure {
            _ = RunicTransliterator.transliterate(longText, to: .elder)
        }
    }
}
