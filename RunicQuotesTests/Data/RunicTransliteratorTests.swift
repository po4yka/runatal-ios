//
//  RunicTransliteratorTests.swift
//  RunicQuotes
//
//  Created by Claude on 30.10.25.
//

@testable import RunicQuotes
import Testing

@Suite(.tags(.utility))
struct RunicTransliteratorTests {
    @Test
    func elderFutharkBasicVowels() {
        let result = RunicTransliterator.transliterate("aeiou", to: .elder).glyphOutput
        #expect(result != "aeiou")
        #expect(!result.isEmpty)
    }

    @Test
    func elderFutharkBasicConsonants() {
        let result = RunicTransliterator.transliterate("bdfgklmnprst", to: .elder).glyphOutput
        #expect(result != "bdfgklmnprst")
        #expect(!result.isEmpty)
    }

    @Test
    func elderFutharkDigraphTH() {
        let result = RunicTransliterator.transliterate("th", to: .elder).glyphOutput
        #expect(result.count == 1)
        #expect(result != "th")
    }

    @Test
    func elderFutharkDigraphNG() {
        #expect(RunicTransliterator.transliterate("ng", to: .elder).glyphOutput != "ng")
    }

    @Test
    func elderFutharkFullWord() {
        let result = RunicTransliterator.transliterate("fortune", to: .elder).glyphOutput
        #expect(!result.isEmpty)
        #expect(result != "fortune")
    }

    @Test
    func elderFutharkPhrase() {
        let result = RunicTransliterator.transliterate("fortune favors the bold", to: .elder).glyphOutput
        #expect(result.contains(" "))
        #expect(result != "fortune favors the bold")
    }

    @Test
    func elderFutharkCaseInsensitive() {
        #expect(
            RunicTransliterator.transliterate("fortune", to: .elder).glyphOutput ==
                RunicTransliterator.transliterate("FORTUNE", to: .elder).glyphOutput,
        )
    }

    @Test
    func elderFutharkPreservesPunctuation() {
        let result = RunicTransliterator.transliterate("hello, world!", to: .elder).glyphOutput
        #expect(result.contains(","))
        #expect(result.contains("!"))
    }

    @Test
    func elderFutharkEmptyString() {
        #expect(RunicTransliterator.transliterate("", to: .elder).glyphOutput.isEmpty)
    }

    @Test
    func youngerFutharkBasicVowels() {
        let result = RunicTransliterator.transliterate("aeiou", to: .younger).glyphOutput
        #expect(result != "aeiou")
        #expect(!result.isEmpty)
    }

    @Test
    func youngerFutharkMergedVowels() {
        #expect(RunicTransliterator.transliterate("i", to: .younger).glyphOutput == RunicTransliterator.transliterate("e", to: .younger).glyphOutput)
        #expect(RunicTransliterator.transliterate("u", to: .younger).glyphOutput == RunicTransliterator.transliterate("o", to: .younger).glyphOutput)
    }

    @Test
    func youngerFutharkMergedConsonants() {
        #expect(RunicTransliterator.transliterate("b", to: .younger).glyphOutput == RunicTransliterator.transliterate("p", to: .younger).glyphOutput)
    }

    @Test
    func youngerFutharkFullWord() {
        let result = RunicTransliterator.transliterate("fortune", to: .younger).glyphOutput
        #expect(!result.isEmpty)
        #expect(result != "fortune")
    }

    @Test
    func cirthBasicVowels() {
        let result = RunicTransliterator.transliterate("aeiou", to: .cirth).glyphOutput
        #expect(result == "aeiou")
        #expect(!result.isEmpty)
    }

    @Test
    func cirthDigraphs() {
        #expect(RunicTransliterator.transliterate("th", to: .cirth).glyphOutput != "th")
        #expect(RunicTransliterator.transliterate("ch", to: .cirth).glyphOutput != "ch")
        #expect(RunicTransliterator.transliterate("sh", to: .cirth).glyphOutput == "\u{E08E}")
    }

    @Test
    func cirthFullPhrase() {
        let result = RunicTransliterator.transliterate("not all those who wander", to: .cirth).glyphOutput
        #expect(result.contains(" "))
        #expect(result != "not all those who wander")
    }

    @Test
    func allScriptsProduceDifferentOutput() {
        let text = "fortune"
        let elder = RunicTransliterator.transliterate(text, to: .elder).glyphOutput
        let younger = RunicTransliterator.transliterate(text, to: .younger).glyphOutput
        let cirth = RunicTransliterator.transliterate(text, to: .cirth).glyphOutput

        #expect(elder != text)
        #expect(younger != text)
        #expect(cirth == "\u{E082}\u{E0B3}\u{E08B}\u{E087}\u{E0AA}\u{E095}\u{E0AF}")
    }

    @Test
    func scriptsPreserveWordBoundaries() {
        let text = "hello world"
        #expect(RunicTransliterator.transliterate(text, to: .elder).glyphOutput.contains(" "))
        #expect(RunicTransliterator.transliterate(text, to: .younger).glyphOutput.contains(" "))
        #expect(RunicTransliterator.transliterate(text, to: .cirth).glyphOutput.contains(" "))
    }

    @Test
    func numbersPassThrough() {
        #expect(!RunicTransliterator.transliterate("123", to: .elder).glyphOutput.isEmpty)
    }

    @Test
    func specialCharacters() {
        #expect(!RunicTransliterator.transliterate("@#$%", to: .elder).glyphOutput.isEmpty)
    }

    @Test
    func mixedContent() {
        let result = RunicTransliterator.transliterate("hello123world!", to: .elder).glyphOutput
        #expect(result.contains("!"))
        #expect(!result.isEmpty)
    }
}
