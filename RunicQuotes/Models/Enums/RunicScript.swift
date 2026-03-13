//
//  RunicScript.swift
//  RunicQuotes
//
//  Created by Claude on 30.09.25.
//

import Foundation

/// Represents the different runic writing systems supported by the app
enum RunicScript: String, Codable, CaseIterable, Identifiable {
    case elder = "Elder Futhark"
    case younger = "Younger Futhark"
    case cirth = "Cirth (Angerthas)"

    var id: String {
        rawValue
    }

    /// Display name for UI
    var displayName: String {
        rawValue
    }

    /// Short description of the script
    var description: String {
        switch self {
        case .elder:
            "Ancient Germanic runes (2nd-8th century)"
        case .younger:
            "Scandinavian runes (9th-11th century)"
        case .cirth:
            "Tolkien's Elvish runes"
        }
    }

    /// Unicode range for the script (nil for PUA-based scripts like Cirth)
    var unicodeRange: ClosedRange<UInt32>? {
        switch self {
        case .elder, .younger:
            0x16A0 ... 0x16EA // Unicode Runic block
        case .cirth:
            nil // Uses Private Use Area
        }
    }
}
