//
//  RunicTransliterator.swift
//  RunicQuotes
//
//  Created by Claude on 30.09.25.
//

import Foundation

/// Converts modern Latin spelling to runes and reports characters outside the supported spelling inventory.
enum RunicTransliterator {
    static func transliterate(_ text: String, to script: RunicScript) -> RunicTransliterationResult {
        let map: [Character: String]
        let digraphs: [String: String]
        switch script {
        case .elder:
            map = elderFutharkMap
            digraphs = elderFutharkDigraphs
        case .younger:
            map = youngerFutharkMap
            digraphs = youngerFutharkDigraphs
        case .cirth:
            map = cirthMap
            digraphs = cirthDigraphs
        }
        let sequenceLengths = Set(digraphs.keys.map(\.count)).sorted(by: >)
        let input = Array(text.map { self.normalizeLatin($0, script: script) }.joined())
        let outputGraphs = Set((Array(map.values) + Array(digraphs.values)).flatMap { Array($0) })
        var output = ""
        var unresolved: [String] = []
        var seen = Set<Character>()
        var index = 0
        while index < input.count {
            if let length = sequenceLengths.first(where: { length in
                index + length <= input.count && digraphs[String(input[index ..< index + length])] != nil
            }), let glyphs = digraphs[String(input[index ..< index + length])] {
                output.append(glyphs)
                index += length
                continue
            }
            let character = input[index]
            if let glyphs = map[character] {
                output.append(glyphs)
            } else {
                output.append(character)
                let literal = character.isWhitespace || character.isPunctuation || character.isNumber || outputGraphs.contains(character)
                if !literal, seen.insert(character).inserted {
                    unresolved.append(String(character))
                }
            }
            index += 1
        }
        return RunicTransliterationResult(glyphOutput: output, unresolvedCharacters: unresolved)
    }

    private static func normalizeLatin(_ character: Character, script: RunicScript) -> String {
        guard character.isLetter, let scalar = character.unicodeScalars.first else { return String(character) }
        let codePoint = scalar.value
        let isLatin = (0x0041 ... 0x007A).contains(codePoint) || (0x00C0 ... 0x024F).contains(codePoint) || (0x1E00 ... 0x1EFF).contains(codePoint)
        guard isLatin else { return String(character) }
        let lower = String(character).lowercased()
        switch lower {
        case "þ": return "th"
        case "ð": return script == .cirth ? "dh" : "th"
        case "æ": return "ae"
        case "œ": return "oe"
        case "ø": return "o"
        case "ß": return "ss"
        case "ł": return "l"
        case "đ": return "d"
        case "ı": return "i"
        default:
            return lower.folding(options: [.diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        }
    }
}
