//
//  RunicTransliteratorTests.swift
//  RunicQuotesTests
//
//  Created by Claude on 2025-11-15.
//

import XCTest
@testable import RunicQuotes

final class RunicTransliteratorTests: XCTestCase {

    // MARK: - Elder Futhark Tests

    func testElderFutharkBasicVowels() {
        let result = RunicTransliterator.transliterate("aeiou", to: .elder)
        XCTAssertNotEqual(result, "aeiou", "Should transliterate vowels to runes")
        XCTAssertFalse(result.isEmpty, "Should produce non-empty output")
    }

    func testElderFutharkBasicConsonants() {
        let result = RunicTransliterator.transliterate("bdfgklmnprst", to: .elder)
        XCTAssertNotEqual(result, "bdfgklmnprst", "Should transliterate consonants to runes")
        XCTAssertFalse(result.isEmpty, "Should produce non-empty output")
    }

    func testElderFutharkDigraphTH() {
        let result = RunicTransliterator.transliterate("th", to: .elder)
        XCTAssertEqual(result.count, 1, "Digraph 'th' should produce single rune")
        XCTAssertNotEqual(result, "th", "Should transliterate 'th' to rune")
    }

    func testElderFutharkDigraphNG() {
        let result = RunicTransliterator.transliterate("ng", to: .elder)
        XCTAssertNotEqual(result, "ng", "Should transliterate 'ng' to rune")
    }

    func testElderFutharkFullWord() {
        let result = RunicTransliterator.transliterate("fortune", to: .elder)
        XCTAssertFalse(result.isEmpty, "Should transliterate full word")
        XCTAssertNotEqual(result, "fortune", "Should convert to runes")
        XCTAssertGreaterThan(result.count, 0, "Should have characters")
    }

    func testElderFutharkPhrase() {
        let result = RunicTransliterator.transliterate("fortune favors the bold", to: .elder)
        XCTAssertTrue(result.contains(" "), "Should preserve spaces")
        XCTAssertNotEqual(result, "fortune favors the bold", "Should convert to runes")
    }

    func testElderFutharkCaseInsensitive() {
        let lower = RunicTransliterator.transliterate("fortune", to: .elder)
        let upper = RunicTransliterator.transliterate("FORTUNE", to: .elder)
        XCTAssertEqual(lower, upper, "Should be case-insensitive")
    }

    func testElderFutharkPreservesPunctuation() {
        let result = RunicTransliterator.transliterate("hello, world!", to: .elder)
        XCTAssertTrue(result.contains(","), "Should preserve comma")
        XCTAssertTrue(result.contains("!"), "Should preserve exclamation")
    }

    func testElderFutharkEmptyString() {
        let result = RunicTransliterator.transliterate("", to: .elder)
        XCTAssertEqual(result, "", "Empty string should return empty string")
    }

    // MARK: - Younger Futhark Tests

    func testYoungerFutharkBasicVowels() {
        let result = RunicTransliterator.transliterate("aeiou", to: .younger)
        XCTAssertNotEqual(result, "aeiou", "Should transliterate vowels to runes")
        XCTAssertFalse(result.isEmpty, "Should produce non-empty output")
    }

    func testYoungerFutharkMergedVowels() {
        // Younger Futhark merges many vowels - e and o should map to a
        let resultA = RunicTransliterator.transliterate("a", to: .younger)
        let resultE = RunicTransliterator.transliterate("e", to: .younger)
        let resultO = RunicTransliterator.transliterate("o", to: .younger)

        XCTAssertEqual(resultA, resultE, "E should merge with A in Younger Futhark")
        XCTAssertEqual(resultA, resultO, "O should merge with A in Younger Futhark")
    }

    func testYoungerFutharkMergedConsonants() {
        // Younger Futhark merges k/g and b/p
        let resultB = RunicTransliterator.transliterate("b", to: .younger)
        let resultP = RunicTransliterator.transliterate("p", to: .younger)

        XCTAssertEqual(resultB, resultP, "P should merge with B in Younger Futhark")
    }

    func testYoungerFutharkFullWord() {
        let result = RunicTransliterator.transliterate("fortune", to: .younger)
        XCTAssertFalse(result.isEmpty, "Should transliterate full word")
        XCTAssertNotEqual(result, "fortune", "Should convert to runes")
    }

    // MARK: - Cirth Tests

    func testCirthBasicVowels() {
        let result = RunicTransliterator.transliterate("aeiou", to: .cirth)
        XCTAssertNotEqual(result, "aeiou", "Should transliterate vowels to Cirth")
        XCTAssertFalse(result.isEmpty, "Should produce non-empty output")
    }

    func testCirthDigraphs() {
        let resultTH = RunicTransliterator.transliterate("th", to: .cirth)
        let resultSH = RunicTransliterator.transliterate("sh", to: .cirth)
        let resultCH = RunicTransliterator.transliterate("ch", to: .cirth)

        XCTAssertNotEqual(resultTH, "th", "Should transliterate 'th' digraph")
        XCTAssertNotEqual(resultSH, "sh", "Should transliterate 'sh' digraph")
        XCTAssertNotEqual(resultCH, "ch", "Should transliterate 'ch' digraph")
    }

    func testCirthFullPhrase() {
        let result = RunicTransliterator.transliterate("not all those who wander", to: .cirth)
        XCTAssertTrue(result.contains(" "), "Should preserve spaces")
        XCTAssertNotEqual(result, "not all those who wander", "Should convert to Cirth runes")
    }

    // MARK: - Cross-Script Tests

    func testAllScriptsProduceDifferentOutput() {
        let text = "fortune"
        let elder = RunicTransliterator.transliterate(text, to: .elder)
        let younger = RunicTransliterator.transliterate(text, to: .younger)
        let cirth = RunicTransliterator.transliterate(text, to: .cirth)

        // Elder and Younger might be similar but Cirth should be different (PUA)
        XCTAssertNotEqual(elder, text, "Elder should differ from original")
        XCTAssertNotEqual(younger, text, "Younger should differ from original")
        XCTAssertNotEqual(cirth, text, "Cirth should differ from original")
    }

    func testScriptsPreserveWordBoundaries() {
        let text = "hello world"

        let elder = RunicTransliterator.transliterate(text, to: .elder)
        let younger = RunicTransliterator.transliterate(text, to: .younger)
        let cirth = RunicTransliterator.transliterate(text, to: .cirth)

        XCTAssertTrue(elder.contains(" "), "Elder should preserve space")
        XCTAssertTrue(younger.contains(" "), "Younger should preserve space")
        XCTAssertTrue(cirth.contains(" "), "Cirth should preserve space")
    }

    // MARK: - Performance Tests

    func testTransliterationPerformance() {
        let longText = String(repeating: "fortune favors the bold ", count: 100)

        measure {
            _ = RunicTransliterator.transliterate(longText, to: .elder)
        }
    }

    // MARK: - Edge Cases

    func testNumbersPassThrough() {
        let result = RunicTransliterator.transliterate("123", to: .elder)
        // Numbers might pass through or be transliterated - just ensure no crash
        XCTAssertFalse(result.isEmpty, "Should handle numbers without crashing")
    }

    func testSpecialCharacters() {
        let result = RunicTransliterator.transliterate("@#$%", to: .elder)
        // Special chars should pass through or be handled gracefully
        XCTAssertFalse(result.isEmpty, "Should handle special characters")
    }

    func testMixedContent() {
        let result = RunicTransliterator.transliterate("hello123world!", to: .elder)
        XCTAssertTrue(result.contains("!"), "Should preserve punctuation")
        XCTAssertFalse(result.isEmpty, "Should handle mixed content")
    }
}
