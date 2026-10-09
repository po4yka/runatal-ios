//
//  YoungerFutharkMap.swift
//  RunicQuotes
//
//  Created by Claude on 30.09.25.
//

import Foundation

// MARK: - Younger Futhark Long-Branch Spelling

/// Modern Latin spelling approximated with the sixteen Viking-Age graphs.
/// Source: Unicode Runic chart and Riksantikvarieämbetet Runskolan.
/// Vowel length, nasality, and historical final ʀ require the historical translation pipeline.
let youngerFutharkMap: [Character: String] = [
    "a": "ᛅ",
    "b": "ᛒ",
    "c": "ᚴ",
    "d": "ᛏ",
    "e": "ᛁ",
    "f": "ᚠ",
    "g": "ᚴ",
    "h": "ᚼ",
    "i": "ᛁ",
    "j": "ᛁ",
    "k": "ᚴ",
    "l": "ᛚ",
    "m": "ᛘ",
    "n": "ᚾ",
    "o": "ᚢ",
    "p": "ᛒ",
    "q": "ᚴ",
    "r": "ᚱ",
    "s": "ᛋ",
    "t": "ᛏ",
    "u": "ᚢ",
    "v": "ᚢ",
    "w": "ᚢ",
    "x": "ᚴᛋ",
    "y": "ᚢ",
    "z": "ᛋ",
]

let youngerFutharkDigraphs: [String: String] = [
    "th": "ᚦ",
    "ng": "ᚾ",
]
