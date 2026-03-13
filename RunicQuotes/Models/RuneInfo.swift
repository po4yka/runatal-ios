//
//  RuneInfo.swift
//  RunicQuotes
//
//  Created by Claude on 12.03.26.
//

import Foundation

/// A single rune entry for reference display.
struct RuneInfo: Identifiable {
    let id: String
    let glyph: String
    let name: String
    let meaning: String
    let sound: String
    let script: RunicScript

    // MARK: - Elder Futhark (24 runes)

    static let elderFuthark: [RuneInfo] = [
        RuneInfo(id: "elder-fehu", glyph: "\u{16A0}", name: "Fehu", meaning: "Wealth", sound: "f", script: .elder),
        RuneInfo(id: "elder-uruz", glyph: "\u{16A2}", name: "Uruz", meaning: "Aurochs", sound: "u", script: .elder),
        RuneInfo(id: "elder-thurisaz", glyph: "\u{16A6}", name: "Thurisaz", meaning: "Giant", sound: "th", script: .elder),
        RuneInfo(id: "elder-ansuz", glyph: "\u{16A8}", name: "Ansuz", meaning: "God", sound: "a", script: .elder),
        RuneInfo(id: "elder-raidho", glyph: "\u{16B1}", name: "Raidho", meaning: "Ride", sound: "r", script: .elder),
        RuneInfo(id: "elder-kenaz", glyph: "\u{16B2}", name: "Kenaz", meaning: "Torch", sound: "k", script: .elder),
        RuneInfo(id: "elder-gebo", glyph: "\u{16B7}", name: "Gebo", meaning: "Gift", sound: "g", script: .elder),
        RuneInfo(id: "elder-wunjo", glyph: "\u{16B9}", name: "Wunjo", meaning: "Joy", sound: "w", script: .elder),
        RuneInfo(id: "elder-hagalaz", glyph: "\u{16BA}", name: "Hagalaz", meaning: "Hail", sound: "h", script: .elder),
        RuneInfo(id: "elder-naudiz", glyph: "\u{16BE}", name: "Naudiz", meaning: "Need", sound: "n", script: .elder),
        RuneInfo(id: "elder-isa", glyph: "\u{16C1}", name: "Isa", meaning: "Ice", sound: "i", script: .elder),
        RuneInfo(id: "elder-jera", glyph: "\u{16C3}", name: "Jera", meaning: "Year", sound: "j", script: .elder),
        RuneInfo(id: "elder-eihwaz", glyph: "\u{16C7}", name: "Eihwaz", meaning: "Yew", sound: "ei", script: .elder),
        RuneInfo(id: "elder-perthro", glyph: "\u{16C8}", name: "Perthro", meaning: "Lot cup", sound: "p", script: .elder),
        RuneInfo(id: "elder-algiz", glyph: "\u{16C9}", name: "Algiz", meaning: "Elk", sound: "z", script: .elder),
        RuneInfo(id: "elder-sowilo", glyph: "\u{16CA}", name: "Sowilo", meaning: "Sun", sound: "s", script: .elder),
        RuneInfo(id: "elder-tiwaz", glyph: "\u{16CF}", name: "Tiwaz", meaning: "Tyr", sound: "t", script: .elder),
        RuneInfo(id: "elder-berkano", glyph: "\u{16D2}", name: "Berkano", meaning: "Birch", sound: "b", script: .elder),
        RuneInfo(id: "elder-ehwaz", glyph: "\u{16D6}", name: "Ehwaz", meaning: "Horse", sound: "e", script: .elder),
        RuneInfo(id: "elder-mannaz", glyph: "\u{16D7}", name: "Mannaz", meaning: "Man", sound: "m", script: .elder),
        RuneInfo(id: "elder-laguz", glyph: "\u{16DA}", name: "Laguz", meaning: "Water", sound: "l", script: .elder),
        RuneInfo(id: "elder-ingwaz", glyph: "\u{16DC}", name: "Ingwaz", meaning: "Ing", sound: "ng", script: .elder),
        RuneInfo(id: "elder-dagaz", glyph: "\u{16DE}", name: "Dagaz", meaning: "Day", sound: "d", script: .elder),
        RuneInfo(id: "elder-othala", glyph: "\u{16DF}", name: "Othala", meaning: "Heritage", sound: "o", script: .elder),
    ]

    // MARK: - Younger Futhark (16 runes)

    static let youngerFuthark: [RuneInfo] = [
        RuneInfo(id: "younger-fe", glyph: "\u{16A0}", name: "Fe", meaning: "Wealth", sound: "f", script: .younger),
        RuneInfo(id: "younger-ur", glyph: "\u{16A2}", name: "Ur", meaning: "Slag/Rain", sound: "u", script: .younger),
        RuneInfo(id: "younger-thurs", glyph: "\u{16A6}", name: "Thurs", meaning: "Giant", sound: "th", script: .younger),
        RuneInfo(id: "younger-ass", glyph: "\u{16A8}", name: "Ass", meaning: "God", sound: "a", script: .younger),
        RuneInfo(id: "younger-reid", glyph: "\u{16B1}", name: "Reid", meaning: "Ride", sound: "r", script: .younger),
        RuneInfo(id: "younger-kaun", glyph: "\u{16B4}", name: "Kaun", meaning: "Ulcer", sound: "k", script: .younger),
        RuneInfo(id: "younger-hagall", glyph: "\u{16BB}", name: "Hagall", meaning: "Hail", sound: "h", script: .younger),
        RuneInfo(id: "younger-naud", glyph: "\u{16BE}", name: "Naud", meaning: "Need", sound: "n", script: .younger),
        RuneInfo(id: "younger-iss", glyph: "\u{16C1}", name: "Iss", meaning: "Ice", sound: "i", script: .younger),
        RuneInfo(id: "younger-ar", glyph: "\u{16C3}", name: "Ar", meaning: "Plenty", sound: "a/j", script: .younger),
        RuneInfo(id: "younger-sol", glyph: "\u{16CA}", name: "Sol", meaning: "Sun", sound: "s", script: .younger),
        RuneInfo(id: "younger-tyr", glyph: "\u{16CF}", name: "Tyr", meaning: "Tyr", sound: "t", script: .younger),
        RuneInfo(id: "younger-bjarkan", glyph: "\u{16D2}", name: "Bjarkan", meaning: "Birch", sound: "b", script: .younger),
        RuneInfo(id: "younger-madr", glyph: "\u{16D7}", name: "Madr", meaning: "Man", sound: "m", script: .younger),
        RuneInfo(id: "younger-logr", glyph: "\u{16DA}", name: "Logr", meaning: "Water", sound: "l", script: .younger),
        RuneInfo(id: "younger-yr", glyph: "\u{16C9}", name: "Yr", meaning: "Yew bow", sound: "R", script: .younger),
    ]

    // MARK: - Cirth (select Angerthas runes)

    static let cirth: [RuneInfo] = [
        RuneInfo(id: "cirth-1", glyph: "p", name: "Certh 1", meaning: "p", sound: "p", script: .cirth),
        RuneInfo(id: "cirth-2", glyph: "b", name: "Certh 2", meaning: "b", sound: "b", script: .cirth),
        RuneInfo(id: "cirth-3", glyph: "f", name: "Certh 3", meaning: "f", sound: "f", script: .cirth),
        RuneInfo(id: "cirth-4", glyph: "c", name: "Certh 4", meaning: "ch/kh", sound: "ch", script: .cirth),
        RuneInfo(id: "cirth-5", glyph: "g", name: "Certh 5", meaning: "g", sound: "g", script: .cirth),
        RuneInfo(id: "cirth-6", glyph: "i", name: "Certh 6", meaning: "i", sound: "i", script: .cirth),
        RuneInfo(id: "cirth-7", glyph: "t", name: "Certh 7", meaning: "t", sound: "t", script: .cirth),
        RuneInfo(id: "cirth-8", glyph: "h", name: "Certh 8", meaning: "h", sound: "h", script: .cirth),
        RuneInfo(id: "cirth-9", glyph: "d", name: "Certh 9", meaning: "d", sound: "d", script: .cirth),
        RuneInfo(id: "cirth-10", glyph: "a", name: "Certh 10", meaning: "a", sound: "a", script: .cirth),
        RuneInfo(id: "cirth-11", glyph: "\u{00FE}", name: "Certh 11", meaning: "th (voiceless)", sound: "th", script: .cirth),
        RuneInfo(id: "cirth-12", glyph: "\u{00F0}", name: "Certh 12", meaning: "dh (voiced)", sound: "dh", script: .cirth),
        RuneInfo(id: "cirth-14", glyph: "n", name: "Certh 14", meaning: "n", sound: "n", script: .cirth),
        RuneInfo(id: "cirth-17", glyph: "w", name: "Certh 17", meaning: "w", sound: "w", script: .cirth),
        RuneInfo(id: "cirth-18", glyph: "m", name: "Certh 18", meaning: "m", sound: "m", script: .cirth),
        RuneInfo(id: "cirth-21", glyph: "n", name: "Certh 21", meaning: "n (dental)", sound: "n", script: .cirth),
        RuneInfo(id: "cirth-22", glyph: "l", name: "Certh 22", meaning: "l", sound: "l", script: .cirth),
        RuneInfo(id: "cirth-28", glyph: "\u{00F1}", name: "Certh 28", meaning: "ng", sound: "ng", script: .cirth),
        RuneInfo(id: "cirth-31", glyph: "z", name: "Certh 31", meaning: "z", sound: "z", script: .cirth),
        RuneInfo(id: "cirth-33", glyph: "s", name: "Certh 33", meaning: "s", sound: "s", script: .cirth),
        RuneInfo(id: "cirth-35", glyph: "e", name: "Certh 35", meaning: "e", sound: "e", script: .cirth),
        RuneInfo(id: "cirth-38", glyph: "o", name: "Certh 38", meaning: "o/u", sound: "o", script: .cirth),
        RuneInfo(id: "cirth-39", glyph: "y", name: "Certh 39", meaning: "y (consonant)", sound: "y", script: .cirth),
        RuneInfo(id: "cirth-40", glyph: "y", name: "Certh 40", meaning: "y (vowel)", sound: "y", script: .cirth),
    ]

    // MARK: - Helpers

    /// Returns runes for the given script.
    static func runes(for script: RunicScript) -> [RuneInfo] {
        switch script {
        case .elder: self.elderFuthark
        case .younger: self.youngerFuthark
        case .cirth: self.cirth
        }
    }

    /// Subtitle for each script (used in grid header).
    static func subtitle(for script: RunicScript) -> String {
        switch script {
        case .elder: "24 runes \u{00B7} c. 150\u{2013}800 CE"
        case .younger: "16 runes \u{00B7} c. 800\u{2013}1100 CE"
        case .cirth: "24 runes \u{00B7} Tolkien's Angerthas"
        }
    }

    static var sample: RuneInfo {
        elderFuthark[0]
    }
}
