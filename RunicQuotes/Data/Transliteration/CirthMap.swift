//
//  CirthMap.swift
//  RunicQuotes
//
//  Created by Claude on 30.09.25.
//

import Foundation

/// Modern spelling transcription in Angerthas Erebor mode. Code points identify
/// graph shapes in the CSUR registry; sounds depend on the selected historical mode.
/// Sources: https://www.evertype.com/standards/csur/cirth.html
/// https://mirrors.mit.edu/CTAN/fonts/cirth/cirth.pdf (Appendix E table).
let cirthMap: [Character: String] = [
    "a": "\u{E0B1}",
    "b": "\u{E081}",
    "c": "\u{E091}",
    "d": "\u{E088}",
    "e": "\u{E0AF}",
    "f": "\u{E082}",
    "g": "\u{E092}",
    "h": "\u{E0A1}",
    "i": "\u{E0A7}",
    "j": "\u{E08D}",
    "k": "\u{E091}",
    "l": "\u{E09E}",
    "m": "\u{E085}",
    "n": "\u{E095}",
    "o": "\u{E0B3}",
    "p": "\u{E080}",
    "q": "\u{E091}",
    "r": "\u{E08B}",
    "s": "\u{E0B9}",
    "t": "\u{E087}",
    "u": "\u{E0AA}",
    "v": "\u{E083}",
    "w": "\u{E0AC}",
    "x": "\u{E090}",
    "y": "\u{E0A8}",
    "z": "\u{E0AB}",
]

let cirthDigraphs: [String: String] = [
    "ngw": "\u{E09A}",
    "ghw": "\u{E099}",
    "khw": "\u{E098}",
    "aa": "\u{E0B2}",
    "ch": "\u{E08C}",
    "dh": "\u{E08A}",
    "ee": "\u{E0B0}",
    "gh": "\u{E094}",
    "gw": "\u{E097}",
    "hw": "\u{E084}",
    "hy": "\u{E0A9}",
    "kh": "\u{E093}",
    "lh": "\u{E09F}",
    "mb": "\u{E086}",
    "nd": "\u{E0A0}",
    "ng": "\u{E0A4}",
    "nw": "\u{E09B}",
    "oe": "\u{E0B6}",
    "oo": "\u{E0B4}",
    "ph": "\u{E082}",
    "ps": "\u{E0BE}",
    "qu": "\u{E096}",
    "sh": "\u{E08E}",
    "th": "\u{E089}",
    "ts": "\u{E0BF}",
    "ue": "\u{E0AD}",
    "zh": "\u{E08F}",
]
