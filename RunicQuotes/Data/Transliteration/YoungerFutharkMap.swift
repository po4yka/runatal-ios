//
//  YoungerFutharkMap.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import Foundation

// MARK: - Younger Futhark Character Mappings

/// Single character mappings for Younger Futhark (16 runes)
/// Younger Futhark is a reduced set compared to Elder Futhark
/// Unicode range: U+16A0–U+16EA (subset)
let youngerFutharkMap: [Character: Character] = [
    // Vowels - Younger Futhark merged many vowels
    "a": "\u{16A8}",  // ᚨ RUNIC LETTER ANSUZ A (ár/áss)
    "e": "\u{16A8}",  // ᚨ uses same as 'a' (merged in Younger)
    "i": "\u{16C1}",  // ᛁ RUNIC LETTER ISAZ IS ISS I (íss)
    "o": "\u{16A8}",  // ᚨ uses same as 'a' (merged in Younger)
    "u": "\u{16A2}",  // ᚢ RUNIC LETTER URUZ U (úr)
    "y": "\u{16C1}",  // ᛁ uses same as 'i' (merged in Younger)

    // Consonants - Younger Futhark has 16 runes total
    "b": "\u{16D2}",  // ᛒ RUNIC LETTER BERKANAN (bjarkan)
    "c": "\u{16B4}",  // ᚴ RUNIC LETTER KAUNA (kaun)
    "d": "\u{16DE}",  // ᛞ RUNIC LETTER DAGAZ (dagr) - though sometimes merged
    "f": "\u{16A0}",  // ᚠ RUNIC LETTER FEHU (fé)
    "g": "\u{16B4}",  // ᚴ RUNIC LETTER KAUNA (k/g merged in Younger)
    "h": "\u{16BB}",  // ᚻ RUNIC LETTER HAGLAZ (hagall)
    "j": "\u{16C3}",  // ᛃ RUNIC LETTER JERAN (ár - year)
    "k": "\u{16B4}",  // ᚴ RUNIC LETTER KAUNA (kaun)
    "l": "\u{16DA}",  // ᛚ RUNIC LETTER LAUKAZ (lögr)
    "m": "\u{16D7}",  // ᛗ RUNIC LETTER MANNAZ (maðr)
    "n": "\u{16BE}",  // ᚾ RUNIC LETTER NAUDIZ (nauðr)
    "p": "\u{16D2}",  // ᛒ uses same as 'b' (merged p/b)
    "q": "\u{16B4}",  // ᚴ uses same as 'k'
    "r": "\u{16B1}",  // ᚱ RUNIC LETTER RAIDO (reið)
    "s": "\u{16CA}",  // ᛊ RUNIC LETTER SOWILO (sól)
    "t": "\u{16CF}",  // ᛏ RUNIC LETTER TIWAZ (týr)
    "v": "\u{16A0}",  // ᚠ uses same as 'f' (merged f/v)
    "w": "\u{16A2}",  // ᚢ uses same as 'u' (merged u/w/v)
    "x": "\u{16B4}",  // ᚴ uses same as 'k'
    "z": "\u{16CA}",  // ᛊ uses same as 's' (merged s/z)
]

/// Digraph mappings for Younger Futhark
let youngerFutharkDigraphs: [String: Character] = [
    "th": "\u{16A6}",  // ᚦ RUNIC LETTER THURISAZ (þurs)
    "ng": "\u{16BE}",  // ᚾ uses nauðr (no separate ng in Younger)
]
