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
        RuneInfo(id: "elder-kenaz", glyph: "\u{16B2}", name: "Kenaz", meaning: "Torch / ulcer (disputed)", sound: "k", script: .elder),
        RuneInfo(id: "elder-gebo", glyph: "\u{16B7}", name: "Gebo", meaning: "Gift", sound: "g", script: .elder),
        RuneInfo(id: "elder-wunjo", glyph: "\u{16B9}", name: "Wunjo", meaning: "Joy", sound: "w", script: .elder),
        RuneInfo(id: "elder-hagalaz", glyph: "\u{16BA}", name: "Hagalaz", meaning: "Hail", sound: "h", script: .elder),
        RuneInfo(id: "elder-naudiz", glyph: "\u{16BE}", name: "Naudiz", meaning: "Need", sound: "n", script: .elder),
        RuneInfo(id: "elder-isa", glyph: "\u{16C1}", name: "Isa", meaning: "Ice", sound: "i", script: .elder),
        RuneInfo(id: "elder-jera", glyph: "\u{16C3}", name: "Jera", meaning: "Year", sound: "j", script: .elder),
        RuneInfo(id: "elder-eihwaz", glyph: "\u{16C7}", name: "Eihwaz", meaning: "Yew", sound: "ï (uncertain)", script: .elder),
        RuneInfo(id: "elder-perthro", glyph: "\u{16C8}", name: "Perthro", meaning: "Uncertain", sound: "p", script: .elder),
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
        RuneInfo(id: "younger-ass", glyph: "\u{16AC}", name: "Óss", meaning: "God / estuary", sound: "ą/o", script: .younger),
        RuneInfo(id: "younger-reid", glyph: "\u{16B1}", name: "Reid", meaning: "Ride", sound: "r", script: .younger),
        RuneInfo(id: "younger-kaun", glyph: "\u{16B4}", name: "Kaun", meaning: "Ulcer", sound: "k", script: .younger),
        RuneInfo(id: "younger-hagall", glyph: "\u{16BC}", name: "Hagall", meaning: "Hail", sound: "h", script: .younger),
        RuneInfo(id: "younger-naud", glyph: "\u{16BE}", name: "Naud", meaning: "Need", sound: "n", script: .younger),
        RuneInfo(id: "younger-iss", glyph: "\u{16C1}", name: "Iss", meaning: "Ice", sound: "i", script: .younger),
        RuneInfo(id: "younger-ar", glyph: "\u{16C5}", name: "Ar", meaning: "Plenty", sound: "a/æ", script: .younger),
        RuneInfo(id: "younger-sol", glyph: "\u{16CB}", name: "Sol", meaning: "Sun", sound: "s", script: .younger),
        RuneInfo(id: "younger-tyr", glyph: "\u{16CF}", name: "Tyr", meaning: "Tyr", sound: "t", script: .younger),
        RuneInfo(id: "younger-bjarkan", glyph: "\u{16D2}", name: "Bjarkan", meaning: "Birch", sound: "b", script: .younger),
        RuneInfo(id: "younger-madr", glyph: "\u{16D8}", name: "Madr", meaning: "Man", sound: "m", script: .younger),
        RuneInfo(id: "younger-logr", glyph: "\u{16DA}", name: "Logr", meaning: "Water", sound: "l", script: .younger),
        RuneInfo(id: "younger-yr", glyph: "\u{16E6}", name: "Yr", meaning: "Yew bow", sound: "ʀ", script: .younger),
    ]

    // MARK: - Cirth (select Angerthas runes)

    static let cirth: [RuneInfo] = CirthGraph.erebor.map { graph in
        RuneInfo(
            id: graph.id,
            glyph: graph.glyph,
            name: "Certh \(graph.number)",
            meaning: "Erebor \(graph.soundLabel)",
            sound: graph.soundLabel,
            script: .cirth,
        )
    }

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
        case .cirth: "\(self.cirth.count) graphs · Angerthas Erebor · fictional script"
        }
    }

    static var sample: RuneInfo {
        elderFuthark[0]
    }
}
