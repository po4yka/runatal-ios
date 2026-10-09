//
//  CirthGraph.swift
//  RunicQuotes
//
//  Created by Claude on 09.10.26.
//

import Foundation

/// Graph identities and numbered sound values from Tolkien's Appendix E table.
/// CSUR is a proposed private-use encoding, not a standardized Unicode script.
/// https://mirrors.mit.edu/CTAN/fonts/cirth/cirth.pdf
/// https://www.evertype.com/standards/csur/cirth.html
struct CirthGraph: Sendable {
    let number: Int
    let glyph: String
    let spelling: String
    let modeNote: String

    var id: String {
        "cirth-erebor-\(self.number)"
    }

    var soundLabel: String {
        ["qu": "kw", "x": "ks", "aa": "ā", "ee": "ē", "oo": "ō", "oe": "ö", "ue": "ü"][self.spelling] ?? self.spelling
    }

    static let erebor: [CirthGraph] = [
        CirthGraph(number: 1, glyph: "\u{E080}", spelling: "p", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 2, glyph: "\u{E081}", spelling: "b", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 3, glyph: "\u{E082}", spelling: "f", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 4, glyph: "\u{E083}", spelling: "v", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 5, glyph: "\u{E084}", spelling: "hw", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 6, glyph: "\u{E085}", spelling: "m", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 7, glyph: "\u{E086}", spelling: "mb", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 8, glyph: "\u{E087}", spelling: "t", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 9, glyph: "\u{E088}", spelling: "d", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 10, glyph: "\u{E089}", spelling: "th", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 11, glyph: "\u{E08A}", spelling: "dh", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 12, glyph: "\u{E08B}", spelling: "r", modeNote: "Moria and Erebor certh12 is r; older Angerthas value n."),
        CirthGraph(number: 13, glyph: "\u{E08C}", spelling: "ch", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 14, glyph: "\u{E08D}", spelling: "j", modeNote: "Erebor restores j14; Moria uses graph29 for j."),
        CirthGraph(number: 15, glyph: "\u{E08E}", spelling: "sh", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 16, glyph: "\u{E08F}", spelling: "zh", modeNote: "Erebor restores zh16; Moria uses graph30 for zh."),
        CirthGraph(number: 17, glyph: "\u{E090}", spelling: "x", modeNote: "Erebor certh17 is ks/x; Moria uses the same graph for z."),
        CirthGraph(number: 18, glyph: "\u{E091}", spelling: "k", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 19, glyph: "\u{E092}", spelling: "g", modeNote: "Erebor also uses certh29 as a variant for g."),
        CirthGraph(number: 20, glyph: "\u{E093}", spelling: "kh", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 21, glyph: "\u{E094}", spelling: "gh", modeNote: "Erebor also uses certh30 as a variant for gh."),
        CirthGraph(number: 22, glyph: "\u{E095}", spelling: "n", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 23, glyph: "\u{E096}", spelling: "qu", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 24, glyph: "\u{E097}", spelling: "gw", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 25, glyph: "\u{E098}", spelling: "khw", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 26, glyph: "\u{E099}", spelling: "ghw", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 27, glyph: "\u{E09A}", spelling: "ngw", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 28, glyph: "\u{E09B}", spelling: "nw", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 31, glyph: "\u{E09E}", spelling: "l", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 32, glyph: "\u{E09F}", spelling: "lh", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 33, glyph: "\u{E0A0}", spelling: "nd", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 34, glyph: "\u{E0A1}", spelling: "h", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 37, glyph: "\u{E0A4}", spelling: "ng", modeNote: "Moria/Erebor certh37: ng; Tolkien marks the value with a question mark in the table."),
        CirthGraph(number: 39, glyph: "\u{E0A7}", spelling: "i", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 40, glyph: "\u{E0A8}", spelling: "y", modeNote: "The table marks the vowel sound assignment as uncertain."),
        CirthGraph(number: 41, glyph: "\u{E0A9}", spelling: "hy", modeNote: "The table marks this sound assignment as uncertain."),
        CirthGraph(number: 42, glyph: "\u{E0AA}", spelling: "u", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 43, glyph: "\u{E0AB}", spelling: "z", modeNote: "Erebor certh43 is z; Moria uses the same graph for long u."),
        CirthGraph(number: 44, glyph: "\u{E0AC}", spelling: "w", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 45, glyph: "\u{E0AD}", spelling: "ue", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 46, glyph: "\u{E0AF}", spelling: "e", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 47, glyph: "\u{E0B0}", spelling: "ee", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 48, glyph: "\u{E0B1}", spelling: "a", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 49, glyph: "\u{E0B2}", spelling: "aa", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 50, glyph: "\u{E0B3}", spelling: "o", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 51, glyph: "\u{E0B4}", spelling: "oo", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 52, glyph: "\u{E0B6}", spelling: "oe", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 54, glyph: "\u{E0B9}", spelling: "s", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 57, glyph: "\u{E0BE}", spelling: "ps", modeNote: "Sound value in the Angerthas Erebor mode."),
        CirthGraph(number: 58, glyph: "\u{E0BF}", spelling: "ts", modeNote: "Sound value in the Angerthas Erebor mode."),
    ]
}
