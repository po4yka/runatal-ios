//
//  RunicScript.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import Foundation

/// Represents the different runic writing systems supported by the app
enum RunicScript: String, Codable, CaseIterable, Identifiable {
    case elder = "Elder Futhark"
    case younger = "Younger Futhark"
    case cirth = "Cirth (Angerthas)"

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        rawValue
    }

    /// Short description of the script
    var description: String {
        switch self {
        case .elder:
            return "Ancient Germanic runes (2nd-8th century)"
        case .younger:
            return "Scandinavian runes (9th-11th century)"
        case .cirth:
            return "Tolkien's Elvish runes"
        }
    }

    /// Unicode range for the script (nil for PUA-based scripts like Cirth)
    var unicodeRange: ClosedRange<UInt32>? {
        switch self {
        case .elder, .younger:
            return 0x16A0...0x16EA // Unicode Runic block
        case .cirth:
            return nil // Uses Private Use Area
        }
    }
}
