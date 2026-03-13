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
        let result = RunicTransliterator.transliterate("aeiou", to: .elder)
        #expect(result != "aeiou")
        #expect(!result.isEmpty)
    }

    @Test
    func elderFutharkBasicConsonants() {
        let result = RunicTransliterator.transliterate("bdfgklmnprst", to: .elder)
        #expect(result != "bdfgklmnprst")
        #expect(!result.isEmpty)
    }

    @Test
    func elderFutharkDigraphTH() {
        let result = RunicTransliterator.transliterate("th", to: .elder)
        #expect(result.count == 1)
        #expect(result != "th")
    }

    @Test
    func elderFutharkDigraphNG() {
        #expect(RunicTransliterator.transliterate("ng", to: .elder) != "ng")
    }

    @Test
    func elderFutharkFullWord() {
        let result = RunicTransliterator.transliterate("fortune", to: .elder)
        #expect(!result.isEmpty)
        #expect(result != "fortune")
    }

    @Test
    func elderFutharkPhrase() {
        let result = RunicTransliterator.transliterate("fortune favors the bold", to: .elder)
        #expect(result.contains(" "))
        #expect(result != "fortune favors the bold")
    }

    @Test
    func elderFutharkCaseInsensitive() {
        #expect(
            RunicTransliterator.transliterate("fortune", to: .elder) ==
                RunicTransliterator.transliterate("FORTUNE", to: .elder),
        )
    }

    @Test
    func elderFutharkPreservesPunctuation() {
        let result = RunicTransliterator.transliterate("hello, world!", to: .elder)
        #expect(result.contains(","))
        #expect(result.contains("!"))
    }

    @Test
    func elderFutharkEmptyString() {
        #expect(RunicTransliterator.transliterate("", to: .elder).isEmpty)
    }

    @Test
    func youngerFutharkBasicVowels() {
        let result = RunicTransliterator.transliterate("aeiou", to: .younger)
        #expect(result != "aeiou")
        #expect(!result.isEmpty)
    }

    @Test
    func youngerFutharkMergedVowels() {
        #expect(RunicTransliterator.transliterate("a", to: .younger) == RunicTransliterator.transliterate("e", to: .younger))
        #expect(RunicTransliterator.transliterate("a", to: .younger) == RunicTransliterator.transliterate("o", to: .younger))
    }

    @Test
    func youngerFutharkMergedConsonants() {
        #expect(RunicTransliterator.transliterate("b", to: .younger) == RunicTransliterator.transliterate("p", to: .younger))
    }

    @Test
    func youngerFutharkFullWord() {
        let result = RunicTransliterator.transliterate("fortune", to: .younger)
        #expect(!result.isEmpty)
        #expect(result != "fortune")
    }

    @Test
    func cirthBasicVowels() {
        let result = RunicTransliterator.transliterate("aeiou", to: .cirth)
        #expect(result == "aeiou")
        #expect(!result.isEmpty)
    }

    @Test
    func cirthDigraphs() {
        #expect(RunicTransliterator.transliterate("th", to: .cirth) != "th")
        #expect(RunicTransliterator.transliterate("ch", to: .cirth) != "ch")
        #expect(RunicTransliterator.transliterate("sh", to: .cirth) == "sh")
    }

    @Test
    func cirthFullPhrase() {
        let result = RunicTransliterator.transliterate("not all those who wander", to: .cirth)
        #expect(result.contains(" "))
        #expect(result != "not all those who wander")
    }

    @Test
    func allScriptsProduceDifferentOutput() {
        let text = "fortune"
        let elder = RunicTransliterator.transliterate(text, to: .elder)
        let younger = RunicTransliterator.transliterate(text, to: .younger)
        let cirth = RunicTransliterator.transliterate(text, to: .cirth)

        #expect(elder != text)
        #expect(younger != text)
        #expect(cirth == text)
    }

    @Test
    func scriptsPreserveWordBoundaries() {
        let text = "hello world"
        #expect(RunicTransliterator.transliterate(text, to: .elder).contains(" "))
        #expect(RunicTransliterator.transliterate(text, to: .younger).contains(" "))
        #expect(RunicTransliterator.transliterate(text, to: .cirth).contains(" "))
    }

    @Test
    func numbersPassThrough() {
        #expect(!RunicTransliterator.transliterate("123", to: .elder).isEmpty)
    }

    @Test
    func specialCharacters() {
        #expect(!RunicTransliterator.transliterate("@#$%", to: .elder).isEmpty)
    }

    @Test
    func mixedContent() {
        let result = RunicTransliterator.transliterate("hello123world!", to: .elder)
        #expect(result.contains("!"))
        #expect(!result.isEmpty)
    }
}
