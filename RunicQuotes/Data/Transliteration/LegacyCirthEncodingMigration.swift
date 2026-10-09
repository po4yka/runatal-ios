//
//  LegacyCirthEncodingMigration.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation
import os

/// Versioned data conversion of the retired Latin-substitution font slots to
/// stable CSUR graph identities. This is not a live transcription mode.
enum LegacyCirthEncodingMigration {
    static let encoding = "CIRTH_CSUR_V1"

    private static let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "CirthMigration")

    static func upgrade(_ quote: Quote) {
        guard quote.cirthEncodingRaw == nil || quote.cirthEncodingRaw == "ANGERTHAS_LATIN_V1" else { return }
        let unknownEncoding = quote.cirthEncodingRaw == nil && quote.runicCirth?.unicodeScalars.contains(where: { (0xE000 ... 0xF8FF).contains($0.value) }) == true
        if unknownEncoding {
            quote.cirthEncodingRaw = "CIRTH_UNKNOWN_V0"
            self.logger.warning("Preserved unrecognized legacy Cirth PUA encoding")
            return
        }
        if let glyphs = quote.runicCirth {
            // Refresh generated spelling only after an exact frozen old-engine
            // match. User/historical overrides retain their visual graph shapes.
            if quote.storedTranslationMetadataData == nil, glyphs == self.generatedLatinV1(quote.textLatin) {
                quote.runicCirth = RunicTransliterator.transliterate(quote.textLatin, to: .cirth).glyphOutput
            } else {
                quote.runicCirth = self.convertSlots(glyphs)
            }
        }
        if let data = quote.storedTranslationMetadataData {
            do {
                quote.storedTranslationMetadataData = try self.convertArtifacts(data)
            } catch {
                self.logger.warning("Preserved unreadable permanent translation metadata during Cirth encoding migration")
            }
        }
        quote.cirthEncodingRaw = self.encoding
    }

    private static func convertArtifacts(_ data: Data) throws -> Data {
        _ = try JSONDecoder().decode([TranslationResult].self, from: data)
        guard var artifacts = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw CocoaError(.coderReadCorrupt)
        }
        for index in artifacts.indices where artifacts[index]["script"] as? String == RunicScript.cirth.rawValue {
            if let glyphs = artifacts[index]["glyphOutput"] as? String {
                artifacts[index]["glyphOutput"] = self.convertSlots(glyphs)
            }
            if var tokens = artifacts[index]["tokenBreakdown"] as? [[String: Any]] {
                for tokenIndex in tokens.indices {
                    if let glyphs = tokens[tokenIndex]["glyphToken"] as? String {
                        tokens[tokenIndex]["glyphToken"] = self.convertSlots(glyphs)
                    }
                }
                artifacts[index]["tokenBreakdown"] = tokens
            }
            let notes = artifacts[index]["notes"] as? [String] ?? []
            artifacts[index]["notes"] = notes + ["Migrated retired Angerthas font slots to CSUR graph encoding; original translation engine and provenance retained."]
        }
        return try JSONSerialization.data(withJSONObject: artifacts, options: [.sortedKeys])
    }

    /// Frozen normalized Latin-slot engine (R5); no runtime caller uses this codec.
    private static func generatedLatinV1(_ text: String) -> String {
        let input = text.map { character -> String in
            guard character.isLetter, let scalar = character.unicodeScalars.first,
                  (0x0041 ... 0x007A).contains(scalar.value) || (0x00C0 ... 0x024F).contains(scalar.value) || (0x1E00 ... 0x1EFF).contains(scalar.value) else { return String(character) }
            let lower = String(character).lowercased()
            let special = ["þ": "th", "ð": "dh", "æ": "ae", "œ": "oe", "ø": "o", "ß": "ss", "ł": "l", "đ": "d", "ı": "i"]
            return special[lower] ?? lower.folding(options: [.diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        }.joined()
        let characters = Array(input)
        let sequences = ["th": "þ", "dh": "ð", "ng": "ñ", "ch": "ç"]
        var output = ""
        var index = 0
        while index < characters.count {
            if index + 1 < characters.count, let graph = sequences[String(characters[index ... index + 1])] {
                output.append(graph)
                index += 2
            } else {
                output.append(characters[index])
                index += 1
            }
        }
        return output
    }

    private static func convertSlots(_ text: String) -> String {
        text.map { self.slots[String($0).lowercased()] ?? String($0) }.joined()
    }

    /// Graph identities verified by comparing the retired Angerthas outlines
    /// against the CSUR chart. The legacy x outline is k+s (two contours),
    /// whereas canonical Erebor x is a different single certh.
    private static let slots: [String: String] = [
        "a": "\u{E0B1}",
        "b": "\u{E081}",
        "c": "\u{E091}",
        "d": "\u{E088}",
        "e": "\u{E0AF}",
        "f": "\u{E082}",
        "g": "\u{E092}",
        "h": "\u{E0A1}",
        "i": "\u{E0A7}",
        "j": "\u{E09C}",
        "k": "\u{E091}",
        "l": "\u{E09E}",
        "m": "\u{E085}",
        "n": "\u{E095}",
        "o": "\u{E0B3}",
        "p": "\u{E080}",
        "q": "\u{E096}",
        "r": "\u{E08B}",
        "s": "\u{E0B9}",
        "t": "\u{E087}",
        "u": "\u{E0AA}",
        "v": "\u{E083}",
        "w": "\u{E0AC}",
        "x": "\u{E091}\u{E0B9}",
        "y": "\u{E0A8}",
        "z": "\u{E090}",
        "þ": "\u{E089}",
        "ð": "\u{E08A}",
        "ç": "\u{E08E}",
        "ñ": "\u{E0A3}",
        "á": "\u{E0B2}",
        "é": "\u{E0B0}",
        "ó": "\u{E0B4}",
        "ú": "\u{E0AB}",
        "ö": "\u{E0B6}",
        "ü": "\u{E0AD}",
    ]
}
