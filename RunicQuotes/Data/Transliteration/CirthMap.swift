//
//  CirthMap.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import Foundation

// MARK: - Cirth (Angerthas) Character Mappings

/// Single character mappings for Cirth/Angerthas.
///
/// The Angerthas Moria font is a Latin-substitution font: each ASCII letter
/// position contains a Cirth rune glyph. Typing 'a' renders the Cirth rune
/// for the 'a' sound, 'b' renders the rune for 'b', etc.
///
/// Because the font handles the visual mapping, single Latin letters map
/// directly to themselves (lowercased). The font file has no glyphs in
/// the Private Use Area.
let cirthMap: [Character: Character] = [
    "a": "a",
    "b": "b",
    "c": "c",
    "d": "d",
    "e": "e",
    "f": "f",
    "g": "g",
    "h": "h",
    "i": "i",
    "j": "j",
    "k": "k",
    "l": "l",
    "m": "m",
    "n": "n",
    "o": "o",
    "p": "p",
    "q": "q",
    "r": "r",
    "s": "s",
    "t": "t",
    "u": "u",
    "v": "v",
    "w": "w",
    "x": "x",
    "y": "y",
    "z": "z",
]

/// Digraph mappings for Cirth (two-character combinations).
///
/// The font includes glyphs at Latin-1 supplement positions for sounds
/// that require a dedicated rune:
///   - þ (U+00FE, thorn)   — voiceless "th" as in 'thin'
///   - ð (U+00F0, eth)     — voiced "th" as in 'this'
///   - ñ (U+00F1, n-tilde) — "ng" nasal
///   - ç (U+00E7, c-cedilla) — "ch"
///
/// Digraphs without a dedicated font glyph are omitted; the transliterator
/// will fall through and render them as two separate rune characters.
let cirthDigraphs: [String: Character] = [
    "th": "\u{00FE}",  // þ — voiceless th (thin)
    "dh": "\u{00F0}",  // ð — voiced th (this)
    "ng": "\u{00F1}",  // ñ — ng nasal
    "ch": "\u{00E7}",  // ç — ch
]

// MARK: - Additional Cirth Information

/// Cirth rune names (for reference and potential future UI display)
let cirthRuneNames: [Int: String] = [
    1: "p",
    2: "b",
    3: "f",
    4: "kh/ch",
    5: "g",
    6: "i",
    7: "t",
    8: "h",
    9: "d",
    10: "a",
    11: "th (thin)",
    12: "dh (this)",
    13: "gh",
    14: "n (dental)",
    15: "ss",
    16: "kw",
    17: "w",
    18: "m",
    19: "mb",
    20: "r (soft)",
    21: "n",
    22: "l",
    23: "ll",
    24: "r (hard)",
    25: "rh",
    26: "l (soft)",
    27: "lh",
    28: "ng",
    29: "sh",
    30: "zh",
    31: "z",
    32: "s (variant)",
    33: "s",
    34: "s (weak)",
    35: "e",
    36: "ng/nd",
    37: "ks",
    38: "o/u",
    39: "y (consonant)",
    40: "y",
    41: "hw",
    42: "y (vowel)",
]
