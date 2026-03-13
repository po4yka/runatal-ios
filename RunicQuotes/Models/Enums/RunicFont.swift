//
//  RunicFont.swift
//  RunicQuotes
//
//  Created by Claude on 30.09.25.
//

import Foundation

/// Represents the different fonts available for runic text rendering
enum RunicFont: String, Codable, CaseIterable, Identifiable {
    case noto = "Noto Sans Runic"
    case babelstone = "BabelStone Runic"
    case cirth = "Cirth Angerthas"

    var id: String {
        rawValue
    }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .noto:
            "Noto Sans"
        case .babelstone:
            "BabelStone"
        case .cirth:
            "Angerthas"
        }
    }

    /// Font file name
    var fileName: String {
        switch self {
        case .noto:
            "NotoSansRunic-Regular.ttf"
        case .babelstone:
            "BabelStoneRunic.ttf"
        case .cirth:
            "CirthAngerthas.ttf"
        }
    }

    /// Description of the font
    var description: String {
        switch self {
        case .noto:
            "Modern, clean Unicode font"
        case .babelstone:
            "Comprehensive historical font"
        case .cirth:
            "Tolkien's Elvish runes"
        }
    }

    /// Returns whether this font is compatible with the given script
    func isCompatible(with script: RunicScript) -> Bool {
        switch (self, script) {
        case (.cirth, .cirth):
            true
        case (.noto, .elder), (.noto, .younger):
            true
        case (.babelstone, .elder), (.babelstone, .younger):
            true
        default:
            false
        }
    }
}
