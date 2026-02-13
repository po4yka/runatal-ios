//
//  RunicTransliterator.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import Foundation

/// Provides transliteration from Latin text to various runic scripts
struct RunicTransliterator {

    // MARK: - Public API

    /// Transliterate Latin text to the specified runic script
    /// - Parameters:
    ///   - text: The Latin text to transliterate
    ///   - script: The target runic script
    /// - Returns: The transliterated runic text
    static func transliterate(_ text: String, to script: RunicScript) -> String {
        switch script {
        case .elder:
            return latinToElderFuthark(text)
        case .younger:
            return latinToYoungerFuthark(text)
        case .cirth:
            return latinToCirth(text)
        }
    }

    // MARK: - Elder Futhark (Unicode U+16A0–U+16EA)

    /// Transliterate to Elder Futhark runes
    private static func latinToElderFuthark(_ text: String) -> String {
        var result = ""
        let normalized = text.lowercased()
        var i = normalized.startIndex

        while i < normalized.endIndex {
            // Check for digraphs first (two-character combinations)
            if i < normalized.index(before: normalized.endIndex) {
                let digraph = String(normalized[i...normalized.index(after: i)])

                if let runeChar = elderFutharkDigraphs[digraph] {
                    result.append(runeChar)
                    i = normalized.index(i, offsetBy: 2)
                    continue
                }
            }

            // Check single character
            let char = normalized[i]
            if let runeChar = elderFutharkMap[char] {
                result.append(runeChar)
            } else if char.isNumber {
                result.append(char)
            } else if char.isWhitespace {
                result.append(" ")
            } else if char.isPunctuation {
                result.append(char)
            }

            i = normalized.index(after: i)
        }

        return result
    }

    // MARK: - Younger Futhark (Unicode U+16A0–U+16EA subset)

    /// Transliterate to Younger Futhark runes
    private static func latinToYoungerFuthark(_ text: String) -> String {
        var result = ""
        let normalized = text.lowercased()
        var i = normalized.startIndex

        while i < normalized.endIndex {
            // Check for digraphs
            if i < normalized.index(before: normalized.endIndex) {
                let digraph = String(normalized[i...normalized.index(after: i)])

                if let runeChar = youngerFutharkDigraphs[digraph] {
                    result.append(runeChar)
                    i = normalized.index(i, offsetBy: 2)
                    continue
                }
            }

            // Check single character
            let char = normalized[i]
            if let runeChar = youngerFutharkMap[char] {
                result.append(runeChar)
            } else if char.isNumber {
                result.append(char)
            } else if char.isWhitespace {
                result.append(" ")
            } else if char.isPunctuation {
                result.append(char)
            }

            i = normalized.index(after: i)
        }

        return result
    }

    // MARK: - Cirth (Latin-substitution font)

    /// Transliterate to Cirth/Angerthas runes (ASCII mapped via Angerthas Moria font)
    private static func latinToCirth(_ text: String) -> String {
        var result = ""
        let normalized = text.lowercased()
        var i = normalized.startIndex

        while i < normalized.endIndex {
            // Check for digraphs (Cirth uses many digraphs like th, sh, ng, etc.)
            if i < normalized.index(before: normalized.endIndex) {
                let digraph = String(normalized[i...normalized.index(after: i)])

                if let runeChar = cirthDigraphs[digraph] {
                    result.append(runeChar)
                    i = normalized.index(i, offsetBy: 2)
                    continue
                }
            }

            // Check single character
            let char = normalized[i]
            if let runeChar = cirthMap[char] {
                result.append(runeChar)
            } else if char.isNumber {
                result.append(char)
            } else if char.isWhitespace {
                result.append(" ")
            } else if char.isPunctuation {
                result.append(char)
            }

            i = normalized.index(after: i)
        }

        return result
    }
}
