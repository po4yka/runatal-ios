//
//  CirthMap.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import Foundation

// MARK: - Cirth (Angerthas) Character Mappings

/// Single character mappings for Cirth/Angerthas
/// Using Private Use Area (PUA) codepoints starting at U+E000
/// These mappings correspond to the Angerthas Moria font (CIRTH.TTF)
///
/// Note: The actual codepoints may vary depending on the Cirth font used.
/// This is a standard mapping based on common Cirth font implementations.
let cirthMap: [Character: Character] = [
    // Vowels
    "a": "\u{E001}",  // Cirth #1 (p in some modes, but often used for 'a')
    "e": "\u{E003}",  // Cirth #3
    "i": "\u{E006}",  // Cirth #6
    "o": "\u{E00C}",  // Cirth #12
    "u": "\u{E009}",  // Cirth #9

    // Consonants
    "b": "\u{E002}",  // Cirth #2 (b)
    "c": "\u{E004}",  // Cirth #4 (ch in Angerthas, k/c)
    "d": "\u{E009}",  // Cirth #9 (d)
    "f": "\u{E003}",  // Cirth #3 (f)
    "g": "\u{E005}",  // Cirth #5 (g)
    "h": "\u{E008}",  // Cirth #8 (h)
    "j": "\u{E02A}",  // Cirth #42 (y/j)
    "k": "\u{E004}",  // Cirth #4 (k/c)
    "l": "\u{E016}",  // Cirth #22 (l)
    "m": "\u{E012}",  // Cirth #18 (m)
    "n": "\u{E015}",  // Cirth #21 (n)
    "p": "\u{E001}",  // Cirth #1 (p)
    "q": "\u{E010}",  // Cirth #16 (kw/q)
    "r": "\u{E018}",  // Cirth #24 (r)
    "s": "\u{E021}",  // Cirth #33 (s)
    "t": "\u{E007}",  // Cirth #7 (t)
    "v": "\u{E002}",  // Cirth #2 (v/b)
    "w": "\u{E011}",  // Cirth #17 (w)
    "x": "\u{E025}",  // Cirth #37 (ks/x)
    "y": "\u{E02A}",  // Cirth #42 (y)
    "z": "\u{E01F}",  // Cirth #31 (z/s variant)
]

/// Digraph mappings for Cirth (two-character combinations)
/// Cirth has many digraphs for sounds like th, sh, ch, ng, etc.
let cirthDigraphs: [String: Character] = [
    "th": "\u{E00B}",  // Cirth #11 (th as in 'thin')
    "dh": "\u{E00C}",  // Cirth #12 (th as in 'this')
    "sh": "\u{E01D}",  // Cirth #29 (sh)
    "ch": "\u{E004}",  // Cirth #4 (ch)
    "gh": "\u{E00D}",  // Cirth #13 (gh)
    "ng": "\u{E024}",  // Cirth #36 (ng)
    "nd": "\u{E024}",  // Cirth #36 (nd variant)
    "mb": "\u{E013}",  // Cirth #19 (mb)
    "kh": "\u{E008}",  // Cirth #8 (kh)
    "wh": "\u{E029}",  // Cirth #41 (hw/wh)
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
