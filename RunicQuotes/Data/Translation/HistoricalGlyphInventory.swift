//
//  HistoricalGlyphInventory.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation

/// Validates generated historical glyphs against the actual supported script.
/// Literal source numbers/symbols may survive, but letters cannot masquerade as runes.
enum HistoricalGlyphInventory {
    static func unsupportedGlyphs(in result: TranslationResult, request: TranslationRequest) -> [String] {
        let inventory = self.characters(for: request.script, variant: request.youngerVariant)
        var literals = Set(request.sourceText.filter { !$0.isLetter && !$0.isWhitespace && !self.isPrivateUse($0) })
        if request.sourceText.contains(where: { ["’", "‘", "ʼ"].contains($0) }) {
            literals.insert("'")
        }
        let outputs = [result.glyphOutput] + result.tokenBreakdown.map(\.glyphToken)
        var seen = Set<Character>()
        return outputs.flatMap { Array($0) }.filter { character in
            !inventory.contains(character) && !character.isWhitespace && !literals.contains(character) && seen.insert(character).inserted
        }.map(String.init)
    }

    private static func characters(for script: RunicScript, variant: YoungerFutharkVariant) -> Set<Character> {
        switch script {
        case .elder:
            return Set("ᚠᚢᚦᚨᚱᚲᚷᚹᚺᚾᛁᛃᛇᛈᛉᛊᛏᛒᛖᛗᛚᛜᛞᛟ")
        case .younger:
            if variant == .shortTwig {
                return Set("ᚠᚢᚦᚭᚱᚴᚽᚿᛁᛆᛌᛐᛓᛙᛚᛧ")
            }
            return Set("ᚠᚢᚦᚬᚱᚴᚼᚾᛁᛅᛋᛏᛒᛘᛚᛦ")
        case .cirth:
            return Set((UInt32(0xE080) ... UInt32(0xE0C1)).compactMap { UnicodeScalar($0) }.map { Character(String($0)) })
        }
    }

    private static func isPrivateUse(_ character: Character) -> Bool {
        character.unicodeScalars.contains {
            (0xE000 ... 0xF8FF).contains($0.value) || (0xF0000 ... 0xFFFFD).contains($0.value) || (0x100000 ... 0x10FFFD).contains($0.value)
        }
    }
}
