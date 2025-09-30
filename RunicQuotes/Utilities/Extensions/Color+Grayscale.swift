//
//  Color+Grayscale.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI

/// Extension providing the grayscale color palette for the liquid glass design
extension Color {
    // MARK: - Grayscale Palette

    /// Pure black (#000000)
    static let pureBlack = Color(white: 0.0)

    /// Dark grays
    static let darkGray1 = Color(white: 0.1)  // #1A1A1A
    static let darkGray2 = Color(white: 0.18) // #2D2D2D
    static let darkGray3 = Color(white: 0.25) // #404040

    /// Mid grays
    static let midGray1 = Color(white: 0.4)   // #666666
    static let midGray2 = Color(white: 0.5)   // #808080
    static let midGray3 = Color(white: 0.6)   // #999999

    /// Light grays
    static let lightGray1 = Color(white: 0.7) // #B3B3B3
    static let lightGray2 = Color(white: 0.8) // #CCCCCC
    static let lightGray3 = Color(white: 0.9) // #E6E6E6

    /// Pure white (#FFFFFF)
    static let pureWhite = Color(white: 1.0)

    // MARK: - Opacity Levels

    /// Get the color with a specific opacity level
    func withGlassOpacity(_ opacity: GlassOpacity) -> Color {
        self.opacity(opacity.value)
    }
}

/// Predefined opacity levels for the liquid glass design
enum GlassOpacity: Double {
    case full = 1.0
    case veryHigh = 0.9
    case high = 0.8
    case mediumHigh = 0.7
    case medium = 0.6
    case mediumLow = 0.5
    case low = 0.4
    case veryLow = 0.3
    case minimal = 0.2
    case faint = 0.1
    case barely = 0.05

    var value: Double { rawValue }
}
