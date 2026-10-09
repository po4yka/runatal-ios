//
//  LegacyGeneratedRuneMigration.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation

/// Frozen encodings used only to identify automatically generated persisted data.
/// Runtime callers must use RunicTransliterator; these tables are not an alternate live API.
enum LegacyGeneratedRuneMigration {
    /// D3's original placeholder migration, confined to explicitly unversioned rows.
    static func upgradeOriginalCirth(_ quotes: [Quote], render: (String, RunicScript) -> RunicTransliterationResult) {
        for quote in quotes {
            guard quote.cirthEncodingRaw == nil, quote.storedTranslationMetadataData == nil,
                  quote.runicCirth == self.originalCirthV0(quote.textLatin) else { continue }
            quote.runicCirth = render(quote.textLatin, .cirth).glyphOutput
            quote.cirthEncodingRaw = LegacyCirthEncodingMigration.encoding
        }
    }

    static func upgradeElder(_ quote: Quote, render: (String, RunicScript) -> RunicTransliterationResult) {
        guard (quote.runicTransliterationVersion ?? 0) < 1 else { return }
        if quote.storedTranslationMetadataData == nil, quote.runicElder == self.elderV1(quote.textLatin) {
            quote.runicElder = render(quote.textLatin, .elder).glyphOutput
        }
        quote.runicTransliterationVersion = 1
    }

    static func upgradeYounger(_ quote: Quote, render: (String, RunicScript) -> RunicTransliterationResult) {
        guard (quote.runicTransliterationVersion ?? 0) < 2 else { return }
        let original = self.render(quote.textLatin, map: self.youngerMapV1, digraphs: ["th": "ᚦ", "ng": "ᚾ"])
        if quote.storedTranslationMetadataData == nil, quote.runicYounger == original {
            quote.runicYounger = render(quote.textLatin, .younger).glyphOutput
        }
        quote.runicTransliterationVersion = 2
    }

    /// Exact frozen initial c6f9f65 placeholder output; unknown/custom PUA
    /// does not confer permission to regenerate the Latin source.
    private static func originalCirthV0(_ text: String) -> String {
        self.render(text, map: self.cirthPlaceholderMapV0, digraphs: self.cirthPlaceholderDigraphsV0, includeNumbers: false)
    }

    private static let cirthPlaceholderMapV0: [Character: Character] = [
        "a": "\u{E001}",
        "e": "\u{E003}",
        "i": "\u{E006}",
        "o": "\u{E00C}",
        "u": "\u{E009}",
        "b": "\u{E002}",
        "c": "\u{E004}",
        "d": "\u{E009}",
        "f": "\u{E003}",
        "g": "\u{E005}",
        "h": "\u{E008}",
        "j": "\u{E02A}",
        "k": "\u{E004}",
        "l": "\u{E016}",
        "m": "\u{E012}",
        "n": "\u{E015}",
        "p": "\u{E001}",
        "q": "\u{E010}",
        "r": "\u{E018}",
        "s": "\u{E021}",
        "t": "\u{E007}",
        "v": "\u{E002}",
        "w": "\u{E011}",
        "x": "\u{E025}",
        "y": "\u{E02A}",
        "z": "\u{E01F}",
    ]

    private static let cirthPlaceholderDigraphsV0: [String: Character] = [
        "th": "\u{E00B}",
        "dh": "\u{E00C}",
        "sh": "\u{E01D}",
        "ch": "\u{E004}",
        "gh": "\u{E00D}",
        "ng": "\u{E024}",
        "nd": "\u{E024}",
        "mb": "\u{E013}",
        "kh": "\u{E008}",
        "wh": "\u{E029}",
    ]

    private static let youngerMapV1: [Character: Character] = Dictionary(
        uniqueKeysWithValues: zip("abcdefghijklmnopqrstuvwxyz", "ᚨᛒᚴᛞᚨᚠᚴᚻᛁᛃᚴᛚᛗᚾᚨᛒᚴᚱᛊᛏᚢᚠᚢᚴᛁᛊ"),
    )

    static func upgradeNormalization(_ quote: Quote, render: (String, RunicScript) -> RunicTransliterationResult) {
        guard (quote.runicTransliterationVersion ?? 0) < 3 else { return }
        if quote.storedTranslationMetadataData == nil {
            if quote.runicElder == self.render(quote.textLatin, map: self.elderMapV2, digraphs: ["th": "ᚦ", "ng": "ᛜ", "ei": "ᛇ"]) {
                quote.runicElder = render(quote.textLatin, .elder).glyphOutput
            }
            if quote.runicYounger == self.render(quote.textLatin, map: self.youngerMapV2, digraphs: ["th": "ᚦ", "ng": "ᚾ"]) {
                quote.runicYounger = render(quote.textLatin, .younger).glyphOutput
            }
            let latinMap = Dictionary(uniqueKeysWithValues: zip("abcdefghijklmnopqrstuvwxyz", "abcdefghijklmnopqrstuvwxyz"))
            if quote.runicCirth == self.render(quote.textLatin, map: latinMap, digraphs: ["th": "þ", "dh": "ð", "ch": "ç", "ng": "ñ"]) {
                quote.runicCirth = render(quote.textLatin, .cirth).glyphOutput
            }
        }
        quote.runicTransliterationVersion = 3
    }

    private static let elderMapV2: [Character: Character] = Dictionary(uniqueKeysWithValues: zip("abcdefghijklmnopqrstuvwxyz", "ᚨᛒᚲᛞᛖᚠᚷᚺᛁᛃᚲᛚᛗᚾᛟᛈᚲᚱᛊᛏᚢᚠᚹᚲᛁᛉ"))
    private static let youngerMapV2: [Character: Character] = Dictionary(uniqueKeysWithValues: zip("abcdefghijklmnopqrstuvwxyz", "ᛅᛒᚴᛏᛁᚠᚴᚼᛁᛁᚴᛚᛘᚾᚢᛒᚴᚱᛋᛏᚢᚢᚢᚴᚢᛋ"))

    static func elderV1(_ text: String) -> String {
        self.render(text, map: self.elderMapV1, digraphs: ["th": "ᚦ", "ng": "ᛜ", "ei": "ᛇ"])
    }

    private static let elderMapV1: [Character: Character] = Dictionary(
        uniqueKeysWithValues: zip("abcdefghijklmnopqrstuvwxyz", "ᚨᛒᚴᛞᛖᚠᚷᚻᛁᛃᚴᛚᛗᚾᚩᛈᚴᚱᛊᛏᚢᚡᚹᚴᛁᛉ"),
    )

    private static func render(_ text: String, map: [Character: Character], digraphs: [String: Character], includeNumbers: Bool = true) -> String {
        let input = Array(text.lowercased())
        var output = ""
        var index = 0
        while index < input.count {
            if index + 1 < input.count, let glyph = digraphs[String(input[index ... index + 1])] {
                output.append(glyph)
                index += 2
                continue
            }
            let character = input[index]
            if let glyph = map[character] {
                output.append(glyph)
            } else if character.isWhitespace {
                output.append(" ")
            } else if (includeNumbers && character.isNumber) || character.isPunctuation {
                output.append(character)
            }
            index += 1
        }
        return output
    }
}
