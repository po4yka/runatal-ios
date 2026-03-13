//
//  RunicFontConfiguration.swift
//  RunicQuotes
//
//  Created by Claude on 30.09.25.
//

import Foundation

/// Configuration helper for runic fonts
enum RunicFontConfiguration {
    /// Get the font name to use for a specific script and font combination
    /// - Parameters:
    ///   - script: The runic script
    ///   - font: The font style
    /// - Returns: The font name to use with SwiftUI's .custom() modifier
    static func fontName(for script: RunicScript, font: RunicFont) -> String {
        switch script {
        case .cirth:
            "Angerthas Moria"
        case .elder, .younger:
            switch font {
            case .noto:
                "Noto Sans Runic"
            case .babelstone:
                "BabelStone Runic"
            case .cirth:
                "Angerthas Moria" // fallback
            }
        }
    }

    /// Get the recommended font for a script (fallback logic)
    /// - Parameter script: The runic script
    /// - Returns: The recommended font for this script
    static func recommendedFont(for script: RunicScript) -> RunicFont {
        switch script {
        case .elder, .younger:
            .noto
        case .cirth:
            .cirth
        }
    }

    /// Check if a font supports a specific script
    /// - Parameters:
    ///   - font: The font to check
    ///   - script: The script to check
    /// - Returns: True if the font supports the script
    static func supports(font: RunicFont, script: RunicScript) -> Bool {
        font.isCompatible(with: script)
    }

    /// Serif font name for quote body text in share cards and display contexts.
    static let serifFontName = "SourceSerif4-Regular"
}
