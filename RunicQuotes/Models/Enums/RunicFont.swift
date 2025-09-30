//
//  RunicFont.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import Foundation

/// Represents the different fonts available for runic text rendering
enum RunicFont: String, Codable, CaseIterable, Identifiable {
    case noto = "Noto Sans Runic"
    case babelstone = "BabelStone Runic"
    case cirth = "Cirth Angerthas"

    var id: String { rawValue }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .noto:
            return "Noto Sans"
        case .babelstone:
            return "BabelStone"
        case .cirth:
            return "Angerthas"
        }
    }

    /// Font file name
    var fileName: String {
        switch self {
        case .noto:
            return "NotoSansRunic-Regular.ttf"
        case .babelstone:
            return "BabelStoneRunic.ttf"
        case .cirth:
            return "CirthAngerthas.ttf"
        }
    }

    /// Description of the font
    var description: String {
        switch self {
        case .noto:
            return "Modern, clean Unicode font"
        case .babelstone:
            return "Comprehensive historical font"
        case .cirth:
            return "Tolkien's Elvish runes"
        }
    }

    /// Returns whether this font is compatible with the given script
    func isCompatible(with script: RunicScript) -> Bool {
        switch (self, script) {
        case (.cirth, .cirth):
            return true
        case (.noto, .elder), (.noto, .younger):
            return true
        case (.babelstone, .elder), (.babelstone, .younger):
            return true
        default:
            return false
        }
    }
}
