//
//  ElderFutharkMap.swift
//  RunicQuotes
//
//  Created by Claude on 30.09.25.
//

import Foundation

// MARK: - Elder Futhark Character Mappings

/// Single character mappings for Elder Futhark (24 runes)
/// Unicode range: U+16A0–U+16EA
let elderFutharkMap: [Character: String] = [
    // Vowels
    "a": "\u{16A8}", // ᚨ RUNIC LETTER ANSUZ A
    "e": "\u{16D6}", // ᛖ RUNIC LETTER EHWAZ EH E
    "i": "\u{16C1}", // ᛁ RUNIC LETTER ISAZ IS ISS I
    "o": "\u{16DF}", // ᛟ Othala, the Elder Futhark o rune
    "u": "\u{16A2}", // ᚢ RUNIC LETTER URUZ U

    // Consonants
    "b": "\u{16D2}", // ᛒ RUNIC LETTER BERKANAN BEORC BJARKAN B
    "c": "\u{16B2}", // ᚲ RUNIC LETTER KAUNA K (c → k)
    "d": "\u{16DE}", // ᛞ RUNIC LETTER DAGAZ DAEG D
    "f": "\u{16A0}", // ᚠ RUNIC LETTER FEHU FEOH FE F
    "g": "\u{16B7}", // ᚷ RUNIC LETTER GEBO GYFU G
    "h": "\u{16BA}", // ᚺ Elder Futhark Hagalaz
    "j": "\u{16C3}", // ᛃ RUNIC LETTER JERAN J
    "k": "\u{16B2}", // ᚲ RUNIC LETTER KAUNA K
    "l": "\u{16DA}", // ᛚ RUNIC LETTER LAUKAZ LAGU LOGR L
    "m": "\u{16D7}", // ᛗ RUNIC LETTER MANNAZ MAN M
    "n": "\u{16BE}", // ᚾ RUNIC LETTER NAUDIZ NYD NAUD N
    "p": "\u{16C8}", // ᛈ RUNIC LETTER PERTHO PEORTH P
    "q": "\u{16B2}", // ᚲ RUNIC LETTER KAUNA (q → k)
    "r": "\u{16B1}", // ᚱ RUNIC LETTER RAIDO RAD REID R
    "s": "\u{16CA}", // ᛊ RUNIC LETTER SOWILO S
    "t": "\u{16CF}", // ᛏ RUNIC LETTER TIWAZ TIR TYR T
    "v": "\u{16A0}", // Modern Latin v is approximated by Fehu; Elder has no dedicated v
    "w": "\u{16B9}", // ᚹ RUNIC LETTER WUNJO WYNN W
    "x": "ᚲᛊ", // Modern x approximated as the complete k+s sound sequence
    "y": "\u{16C1}", // ᛁ RUNIC LETTER ISAZ IS ISS I (y → i)
    "z": "\u{16C9}", // ᛉ RUNIC LETTER ALGIZ EOLHX
]

/// Digraph mappings for Elder Futhark (two-character combinations)
let elderFutharkDigraphs: [String: String] = [
    "th": "\u{16A6}", // ᚦ RUNIC LETTER THURISAZ THURS THORN
    "ng": "\u{16DC}", // ᛜ RUNIC LETTER INGWAZ
    "ei": "\u{16C7}", // ᛇ RUNIC LETTER IWAZ EOH (ei diphthong)
]
