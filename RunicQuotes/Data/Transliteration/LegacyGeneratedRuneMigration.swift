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
    static func upgradeOriginalCirth(_ quotes: [Quote], render: (String, RunicScript) -> String) {
        for quote in quotes {
            guard quote.cirthEncodingRaw == nil, let cirth = quote.runicCirth,
                  cirth.unicodeScalars.contains(where: { (0xE000 ... 0xE02A).contains($0.value) }) else { continue }
            quote.runicCirth = render(quote.textLatin, .cirth)
            quote.cirthEncodingRaw = "ANGERTHAS_LATIN_V1"
        }
    }

    static func upgradeElder(_ quote: Quote, render: (String, RunicScript) -> String) {
        guard (quote.runicTransliterationVersion ?? 0) < 1 else { return }
        if quote.storedTranslationMetadataData == nil, quote.runicElder == self.elderV1(quote.textLatin) {
            quote.runicElder = render(quote.textLatin, .elder)
        }
        quote.runicTransliterationVersion = 1
    }

    static func elderV1(_ text: String) -> String {
        self.render(text, map: self.elderMapV1, digraphs: ["th": "ᚦ", "ng": "ᛜ", "ei": "ᛇ"])
    }

    private static let elderMapV1: [Character: Character] = Dictionary(
        uniqueKeysWithValues: zip("abcdefghijklmnopqrstuvwxyz", "ᚨᛒᚴᛞᛖᚠᚷᚻᛁᛃᚴᛚᛗᚾᚩᛈᚴᚱᛊᛏᚢᚡᚹᚴᛁᛉ"),
    )

    private static func render(_ text: String, map: [Character: Character], digraphs: [String: Character]) -> String {
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
            } else if character.isNumber || character.isPunctuation {
                output.append(character)
            }
            index += 1
        }
        return output
    }
}
